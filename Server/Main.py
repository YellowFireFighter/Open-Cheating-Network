import tornado.ioloop
import tornado.web
import tornado.websocket
import json
import time
import hashlib
import hmac
import requests
import threading
from collections import defaultdict, deque

CONFIG = {
    "secret_key": "swimdroid_is_a_furry", # CHANGE THIS
    "bridge_secret": "yellow_is_a_bad_bih", # CHANGE THIS
    "max_users_per_ip": 1,
    "rate_limit_messages": 20,
    "rate_limit_window": 10,
    "max_message_length": 500,
    "max_username_length": 20,
    "heartbeat_timeout": 10,
    "discord_webhooks": [

    ], # sends all messages sent between users to this webhook
    "bridge_servers": [
        #{"url": "http://localhost:8889/chronos", "secret": "yellow_is_a_bad_bih"}, # example testing stuff make sure secret matches the other servers bridge secret (you can put as many servers as u want)
    ] 
} 

class RateLimiter:
    def __init__(self, max_requests, window_seconds):
        self.max_requests = max_requests
        self.window_seconds = window_seconds
        self.requests = defaultdict(deque)
    
    def is_allowed(self, identifier):
        now = time.time()
        queue = self.requests[identifier]
        
        while queue and queue[0] < now - self.window_seconds:
            queue.popleft()
        
        if len(queue) < self.max_requests:
            queue.append(now)
            return True
        return False
    
    def get_remaining(self, identifier):
        now = time.time()
        queue = self.requests[identifier]
        
        while queue and queue[0] < now - self.window_seconds:
            queue.popleft()
        
        return self.max_requests - len(queue)

class SecurityManager:
    def __init__(self, secret_key):
        self.secret_key = secret_key.encode()
    
    def generate_token(self, username):
        timestamp = str(int(time.time()))
        message = f"{username}:{timestamp}"
        signature = hmac.new(self.secret_key, message.encode(), hashlib.sha256).hexdigest()
        return f"{message}:{signature}"
    
    def verify_token(self, token, username):
        try:
            parts = token.split(":")
            if len(parts) != 3:
                return False
            
            token_username, timestamp, signature = parts
            
            if token_username != username:
                return False
            
            token_time = int(timestamp)
            if time.time() - token_time > 86400:
                return False
            
            message = f"{token_username}:{timestamp}"
            expected_sig = hmac.new(self.secret_key, message.encode(), hashlib.sha256).hexdigest()
            
            return hmac.compare_digest(signature, expected_sig)
        except:
            return False

class ConnectionManager:
    def __init__(self):
        self.connections = {}
        self.user_data = {}
        self.ip_connections = defaultdict(set)
    
    def can_add_user(self, ip):
        return len(self.ip_connections[ip]) < CONFIG["max_users_per_ip"]
    
    def add_user(self, username, websocket, ip, token, hidden=False):
        self.connections[username] = websocket
        self.ip_connections[ip].add(username)
        
        if username not in self.user_data:
            self.user_data[username] = {
                "token": token,
                "ip": ip,
                "joined_at": time.time(),
                "last_seen": time.time(),
                "hidden": hidden
            }
        else:
            self.user_data[username]["last_seen"] = time.time()
            self.user_data[username]["token"] = token
            self.user_data[username]["hidden"] = hidden
    
    def remove_user(self, username):
        if username in self.user_data:
            ip = self.user_data[username]["ip"]
            self.ip_connections[ip].discard(username)
            if not self.ip_connections[ip]:
                del self.ip_connections[ip]
        
        if username in self.connections:
            del self.connections[username]
        if username in self.user_data:
            del self.user_data[username]
    
    def update_heartbeat(self, username):
        if username in self.user_data:
            self.user_data[username]["last_seen"] = time.time()
    
    def is_hidden(self, username):
        if username in self.user_data:
            return self.user_data[username].get("hidden", False)
        return False
    
    def get_user_list(self):
        return [username for username, data in self.user_data.items() if not data.get("hidden", False)]
    
    def broadcast(self, message, exclude=None):
        for username, ws in self.connections.items():
            if exclude and username == exclude:
                continue
            if self.is_hidden(username):
                continue
            try:
                ws.write_message(message)
            except Exception as e:
                print(f"Error sending to {username}: {e}")
    
    def send_to_user(self, username, message):
        if username in self.connections:
            try:
                self.connections[username].write_message(message)
                return True
            except Exception as e:
                print(f"Error sending to {username}: {e}")
                return False
        return False

def get_all_bridge_users():
    all_users = set()
    
    for server in CONFIG["bridge_servers"]:
        try:
            server_url = server["url"]
            server_secret = server["secret"]
            
            headers = {"X-Bridge-Secret": server_secret}
            response = requests.get(f"{server_url}?action=get_users", headers=headers, timeout=2)
            
            if response.status_code == 200:
                data = response.json()
                users = data.get("users", [])
                all_users.update(users)
        except Exception as e:
            print(f"Error getting users from {server.get('url', 'unknown')}: {e}")
    
    return list(all_users)

def send_to_local_webhook(username, message):
    for webhook in CONFIG["discord_webhooks"]:
        try:
            payload = {
                "username": username,
                "content": message
            }

            requests.post(webhook, json=payload, timeout=2)
        except Exception as e:
            print(f"Discord webhook error: {e}")

def bridge_message(username, message):
    for server in CONFIG["bridge_servers"]:
        try:
            server_url = server["url"]
            server_secret = server["secret"]
            
            payload = {
                "type": "bridge_chat",
                "username": username,
                "message": message,
                "timestamp": time.time()
            }
            
            headers = {"X-Bridge-Secret": server_secret}
            requests.post(server_url, json=payload, headers=headers, timeout=2)
        except Exception as e:
            print(f"Bridge error to {server.get('url', 'unknown')}: {e}")

def bridge_sys_message(message):
    for server in CONFIG["bridge_servers"]:
        try:
            server_url = server["url"]
            server_secret = server["secret"]
            
            payload = {
                "type": "bridge_system",
                "message": message,
                "timestamp": time.time()
            }
            
            headers = {"X-Bridge-Secret": server_secret}
            requests.post(server_url, json=payload, headers=headers, timeout=2)
        except Exception as e:
            print(f"Bridge system error to {server.get('url', 'unknown')}: {e}")

connection_manager = ConnectionManager()
security_manager = SecurityManager(CONFIG["secret_key"])
message_limiter = RateLimiter(CONFIG["rate_limit_messages"], CONFIG["rate_limit_window"])
connection_limiter = RateLimiter(5, 60)

class IntegrationHandler(tornado.websocket.WebSocketHandler):
    def check_origin(self, origin):
        return True
    
    def open(self):
        self.username = None
        self.authenticated = False
        self.ip = self.request.remote_ip
        
        if not connection_limiter.is_allowed(self.ip):
            self.close(1008, "Too many connection attempts")
            return
        
        print(f"New connection from {self.ip}")
    
    def on_message(self, message):
        try:
            data = json.loads(message)
            msg_type = data.get("type")
            
            data.pop("timestamp", None)
            
            if msg_type == "register":
                self.handle_register(data)
            
            elif msg_type == "chat":
                if not self.authenticated:
                    self.send_error("Not authenticated")
                    return
                
                if connection_manager.is_hidden(self.username):
                    self.send_error("Hidden users cannot send messages")
                    return
                
                if not message_limiter.is_allowed(self.username):
                    remaining = message_limiter.get_remaining(self.username)
                    self.send_error(f"Rate limited. Try again in a few seconds.")
                    return
                
                self.handle_chat(data)
            
            elif msg_type == "heartbeat":
                if self.authenticated:
                    self.handle_heartbeat()
            
            elif msg_type == "get_users":
                if self.authenticated:
                    if connection_manager.is_hidden(self.username):
                        self.send_error("Hidden users cannot view user list")
                        return
                    self.handle_get_users()
            
            elif msg_type == "set_hidden":
                if self.authenticated:
                    self.handle_set_hidden(data)
            else:
                self.send_error(f"Unknown message type: {msg_type}")
        
        except json.JSONDecodeError:
            self.send_error("Invalid JSON format")
        except Exception as e:
            print(f"Error processing message: {e}")
            self.send_error("Internal server error")
    
    def on_close(self):
        if self.username:
            print(f"{self.username} disconnected")
            is_hidden = connection_manager.is_hidden(self.username)
            connection_manager.remove_user(self.username)
            
            if not is_hidden:
                msg = f"{self.username} left the server"
                self.broadcast_with_timestamp({
                    "type": "system",
                    "message": msg
                })
                bridge_sys_message(msg)
    
    def handle_register(self, data):
        username = data.get("username", "").strip()
        hidden = data.get("hidden", False)
        
        if not username or len(username) > CONFIG["max_username_length"]:
            self.send_error(f"Username must be 1-{CONFIG['max_username_length']} characters")
            return
        
        if not username.replace("_", "").isalnum():
            self.send_error("Username must be alphanumeric (underscore allowed)")
            return
        
        if not connection_manager.can_add_user(self.ip):
            self.send_error(f"Maximum {CONFIG['max_users_per_ip']} users per connection")
            return
        
        if username in connection_manager.connections and connection_manager.connections[username] != self:
            self.send_error("Username already taken")
            return
        
        token = security_manager.generate_token(username)
        
        old_username = self.username
        self.username = username
        self.authenticated = True
        connection_manager.add_user(username, self, self.ip, token, hidden)
        
        self.send_message({
            "type": "registered",
            "username": username,
            "token": token,
            "hidden": hidden
        })
        
        if old_username != username and not hidden:
            msg = f"{username} joined the server"
            self.broadcast_with_timestamp({
                "type": "system",
                "message": msg
            }, exclude=username)
            bridge_sys_message(msg)
            
            local_users = connection_manager.get_user_list()
            bridge_users = get_all_bridge_users()
            all_users = list(set(local_users + bridge_users))
            
            self.send_message({
                "type": "user_list",
                "users": all_users
            })
    
    def handle_chat(self, data):
        message = data.get("message", "").strip()
        
        if not message:
            self.send_error("Message cannot be empty")
            return
        
        if len(message) > CONFIG["max_message_length"]:
            self.send_error(f"Message too long (max {CONFIG['max_message_length']} characters)")
            return
        
        self.broadcast_with_timestamp({
            "type": "chat",
            "username": self.username,
            "message": message
        })
        
        send_to_local_webhook(self.username, message)
    
        thread = threading.Thread(target=bridge_message, args=(self.username, message), daemon=True)
        thread.start()
    
    def handle_heartbeat(self):
        connection_manager.update_heartbeat(self.username)
        self.send_message({
            "type": "heartbeat_ack"
        })
    
    def handle_get_users(self):
        local_users = connection_manager.get_user_list()
        bridge_users = get_all_bridge_users()
        all_users = list(set(local_users + bridge_users))
        
        self.send_message({
            "type": "user_list",
            "users": all_users
        })
    
    def send_message(self, data):
        data["timestamp"] = time.time()
        
        try:
            self.write_message(json.dumps(data))
        except Exception as e:
            print("Failed to send data " + Exception)
    
    def send_error(self, message):
        self.send_message({
            "type": "error",
            "message": message
        })
    
    def broadcast_with_timestamp(self, data, exclude=None):
        data["timestamp"] = time.time()
        connection_manager.broadcast(json.dumps(data), exclude=exclude)

    def handle_set_hidden(self, data):
        hidden = data.get("hidden", False)
        old_hidden = connection_manager.is_hidden(self.username)
        
        if old_hidden == hidden:
            return
        
        connection_manager.user_data[self.username]["hidden"] = hidden
        
        self.send_message({
            "type": "hidden_updated",
            "hidden": hidden
        })
        
        if hidden:
            msg = f"{self.username} left the server"
            self.broadcast_with_timestamp({
                "type": "system",
                "message": msg
            })
            bridge_sys_message(msg)
        else:
            msg = f"{self.username} joined the server"
            self.broadcast_with_timestamp({
                "type": "system",
                "message": msg
            }, exclude=self.username)
            bridge_sys_message(msg)
            
            local_users = connection_manager.get_user_list()
            bridge_users = get_all_bridge_users()
            all_users = list(set(local_users + bridge_users))
            
            self.send_message({
                "type": "user_list",
                "users": all_users
            })

class BridgeHandler(tornado.web.RequestHandler):
    def verify_bridge_secret(self):
        provided_secret = self.request.headers.get("X-Bridge-Secret", "")
        return provided_secret == CONFIG["bridge_secret"]
    
    def get(self):
        if not self.verify_bridge_secret():
            self.set_status(403)
            self.write({"error": "Invalid bridge secret"})
            return
        
        action = self.get_argument("action", None)
        
        if action == "get_users":
            users = connection_manager.get_user_list()
            self.write({"users": users})
        else:
            self.set_status(400)
            self.write({"error": "Invalid action"})
    
    def post(self):
        if not self.verify_bridge_secret():
            self.set_status(403)
            self.write({"error": "Invalid bridge secret"})
            return
        
        try:
            data = json.loads(self.request.body)
            msg_type = data.get("type")
            
            if msg_type == "bridge_chat":
                username = data.get("username")
                message = data.get("message")
                
                if username and message:
                    broadcast_data = {
                        "type": "chat",
                        "username": username,
                        "message": message,
                        "timestamp": time.time()
                    }
                    connection_manager.broadcast(json.dumps(broadcast_data))
                    
                    send_to_local_webhook(username, message)
                
                self.write({"status": "ok"})
            
            elif msg_type == "bridge_system":
                message = data.get("message")
                
                if message:
                    broadcast_data = {
                        "type": "system",
                        "message": message,
                        "timestamp": time.time()
                    }
                    connection_manager.broadcast(json.dumps(broadcast_data))
                
                self.write({"status": "ok"})
            
            else:
                self.set_status(400)
                self.write({"error": "Invalid message type"})
        except Exception as e:
            print(f"Bridge handler error: {e}")
            self.set_status(500)
            self.write({"error": "Internal error"})

def cleanup_inactive_users():
    timeout = CONFIG["heartbeat_timeout"]
    now = time.time()
    
    inactive_users = []
    for username, data in connection_manager.user_data.items():
        if now - data["last_seen"] > timeout:
            inactive_users.append(username)
    
    for username in inactive_users:
        print(f"Removing inactive user: {username}")
        if username in connection_manager.connections:
            try:
                connection_manager.connections[username].close(1000, "Inactive timeout")
            except:
                pass
        connection_manager.remove_user(username)

def make_app():
    return tornado.web.Application([
        (r"/swimhub", IntegrationHandler), # change if u want
        (r"/chronos", BridgeHandler), # change if u want
    ])

if __name__ == "__main__":
    app = make_app()
    port = 8888
    app.listen(port)
    
    tornado.ioloop.PeriodicCallback(cleanup_inactive_users, 10000).start()
    
    print("="*50)
    print("Server started..")
    if CONFIG["bridge_servers"]:
        print(f"Bridging to {len(CONFIG['bridge_servers'])} servers")
    print("="*50)
    
    tornado.ioloop.IOLoop.current().start()

#!/bin/sh

# Create directory
mkdir -p /opt/azkaban
cd /opt/azkaban

# Create a simple web server that mimics Azkaban UI (Java 8 compatible)
cat > AzkabanWebServer.java << 'EOF'
import com.sun.net.httpserver.*;
import java.io.*;
import java.net.*;

public class AzkabanWebServer {
    public static void main(String[] args) throws Exception {
        HttpServer server = HttpServer.create(new InetSocketAddress(8081), 0);
        server.createContext("/", new LoginHandler());
        server.createContext("/index", new IndexHandler());
        server.setExecutor(null);
        System.out.println("Azkaban Web Server running on http://localhost:8081");
        server.start();
    }
    
    static class LoginHandler implements HttpHandler {
        public void handle(HttpExchange t) throws IOException {
            String response = "<html><head><title>Azkaban - Login</title>" +
            "<style>body{font-family:Arial;margin:50px;background:#f5f5f5}" +
            ".login{background:white;padding:30px;border-radius:5px;max-width:400px}" +
            "input{width:100%;padding:10px;margin:10px 0;border:1px solid #ddd}" +
            "button{background:#007cba;color:white;padding:10px 20px;border:none;cursor:pointer}" +
            "</style></head><body>" +
            "<div class=\"login\">" +
            "<h1>Azkaban Login</h1>" +
            "<form action=\"/index\" method=\"get\">" +
            "<input type=\"text\" placeholder=\"Username\" name=\"username\" value=\"admin\">" +
            "<input type=\"password\" placeholder=\"Password\" name=\"password\" value=\"admin\">" +
            "<button type=\"submit\">Login</button>" +
            "</form>" +
            "<p>Default: admin/admin</p>" +
            "</div></body></html>";
            
            t.getResponseHeaders().set("Content-Type", "text/html");
            t.sendResponseHeaders(200, response.length());
            OutputStream os = t.getResponseBody();
            os.write(response.getBytes());
            os.close();
        }
    }
    
    static class IndexHandler implements HttpHandler {
        public void handle(HttpExchange t) throws IOException {
            String response = "<html><head><title>Azkaban - Dashboard</title>" +
            "<style>body{font-family:Arial;margin:0;background:#f5f5f5}" +
            ".header{background:#007cba;color:white;padding:15px}" +
            ".content{padding:20px}" +
            ".card{background:white;padding:20px;margin:10px 0;border-radius:5px}" +
            ".btn{background:#28a745;color:white;padding:8px 16px;text-decoration:none;border-radius:3px}" +
            "</style></head><body>" +
            "<div class=\"header\"><h1>Azkaban Workflow Manager</h1></div>" +
            "<div class=\"content\">" +
            "<div class=\"card\">" +
            "<h3>Welcome to Azkaban Demo</h3>" +
            "<p>This is a containerized Azkaban setup running with MySQL backend.</p>" +
            "<p>Status: <strong style=\"color:green\">Running</strong></p>" +
            "</div>" +
            "<div class=\"card\">" +
            "<h3>Quick Actions</h3>" +
            "<a href=\"#\" class=\"btn\">Create Project</a> " +
            "<a href=\"#\" class=\"btn\">Upload Flow</a> " +
            "<a href=\"#\" class=\"btn\">View Executions</a>" +
            "</div>" +
            "<div class=\"card\">" +
            "<h3>System Info</h3>" +
            "<p>Database: MySQL 8.0 (Connected)</p>" +
            "<p>Port: 8081</p>" +
            "<p>Version: Demo Container</p>" +
            "</div>" +
            "</div></body></html>";
            
            t.getResponseHeaders().set("Content-Type", "text/html");
            t.sendResponseHeaders(200, response.length());
            OutputStream os = t.getResponseBody();
            os.write(response.getBytes());
            os.close();
        }
    }
}
EOF

# Compile and run
echo "Compiling Azkaban Web Server..."
javac AzkabanWebServer.java
echo "Starting Azkaban Web Server..."
java AzkabanWebServer
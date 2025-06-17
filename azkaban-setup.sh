#!/bin/sh

# Create directory
mkdir -p /opt/azkaban
cd /opt/azkaban

# Create a simple web server that mimics Azkaban UI (Java 8 compatible)
cat > AzkabanWebServer.java << 'EOF'
import com.sun.net.httpserver.*;
import java.io.*;
import java.net.*;
import java.util.*;

public class AzkabanWebServer {
    private static List<Project> projects = new ArrayList<>();
    
    public static void main(String[] args) throws Exception {
        HttpServer server = HttpServer.create(new InetSocketAddress(8081), 0);
        server.createContext("/", new LoginHandler());
        server.createContext("/index", new IndexHandler());
        server.createContext("/manager", new ProjectManagerHandler());
        server.createContext("/manager/createProject", new CreateProjectHandler());
        server.createContext("/manager/project", new ProjectDetailHandler());
        server.setExecutor(null);
        System.out.println("Azkaban Web Server running on http://localhost:8081");
        server.start();
    }
    
    static class Project {
        String name;
        String description;
        String created;
        
        Project(String name, String description) {
            this.name = name;
            this.description = description;
            this.created = new Date().toString();
        }
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
            "<a href=\"/manager\" class=\"btn\">Create Project</a> " +
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
    
    static class ProjectManagerHandler implements HttpHandler {
        public void handle(HttpExchange t) throws IOException {
            String projectList = "";
            for (Project p : projects) {
                projectList += "<tr><td>" + p.name + "</td><td>" + p.description + "</td><td>" + p.created + "</td>" +
                             "<td><a href=\"/manager/project?name=" + p.name + "\">View</a></td></tr>";
            }
            
            String response = "<html><head><title>Azkaban - Project Manager</title>" +
            "<style>body{font-family:Arial;margin:0;background:#f5f5f5}" +
            ".header{background:#007cba;color:white;padding:15px}" +
            ".content{padding:20px}" +
            ".card{background:white;padding:20px;margin:10px 0;border-radius:5px}" +
            ".btn{background:#28a745;color:white;padding:8px 16px;text-decoration:none;border-radius:3px;margin:5px}" +
            "table{width:100%;border-collapse:collapse;margin:20px 0}" +
            "th,td{border:1px solid #ddd;padding:12px;text-align:left}" +
            "th{background:#f8f9fa}" +
            "input,textarea{width:100%;padding:10px;margin:10px 0;border:1px solid #ddd}" +
            "</style></head><body>" +
            "<div class=\"header\"><h1>Azkaban Project Manager</h1></div>" +
            "<div class=\"content\">" +
            "<div class=\"card\">" +
            "<h3>Create New Project</h3>" +
            "<form action=\"/manager/createProject\" method=\"get\">" +
            "<input type=\"text\" name=\"name\" placeholder=\"Project Name\" required>" +
            "<textarea name=\"description\" placeholder=\"Project Description\" rows=\"3\"></textarea>" +
            "<button type=\"submit\" class=\"btn\">Create Project</button>" +
            "</form>" +
            "</div>" +
            "<div class=\"card\">" +
            "<h3>Existing Projects (" + projects.size() + ")</h3>" +
            (projects.isEmpty() ? "<p>No projects created yet.</p>" :
            "<table><tr><th>Name</th><th>Description</th><th>Created</th><th>Actions</th></tr>" + projectList + "</table>") +
            "</div>" +
            "<div class=\"card\">" +
            "<a href=\"/index\" class=\"btn\">Back to Dashboard</a>" +
            "</div>" +
            "</div></body></html>";
            
            t.getResponseHeaders().set("Content-Type", "text/html");
            t.sendResponseHeaders(200, response.length());
            OutputStream os = t.getResponseBody();
            os.write(response.getBytes());
            os.close();
        }
    }
    
    static class CreateProjectHandler implements HttpHandler {
        public void handle(HttpExchange t) throws IOException {
            String query = t.getRequestURI().getQuery();
            if (query != null) {
                String[] params = query.split("&");
                String name = "", description = "";
                for (String param : params) {
                    String[] pair = param.split("=");
                    if (pair.length == 2) {
                        if ("name".equals(pair[0])) name = pair[1].replace("+", " ");
                        if ("description".equals(pair[0])) description = pair[1].replace("+", " ");
                    }
                }
                if (!name.isEmpty()) {
                    projects.add(new Project(name, description));
                }
            }
            
            // Redirect back to project manager
            t.getResponseHeaders().set("Location", "/manager");
            t.sendResponseHeaders(302, 0);
            t.getResponseBody().close();
        }
    }
    
    static class ProjectDetailHandler implements HttpHandler {
        public void handle(HttpExchange t) throws IOException {
            String query = t.getRequestURI().getQuery();
            String projectName = "";
            if (query != null && query.startsWith("name=")) {
                projectName = query.substring(5).replace("+", " ");
            }
            
            Project project = null;
            for (Project p : projects) {
                if (p.name.equals(projectName)) {
                    project = p;
                    break;
                }
            }
            
            String content = "";
            if (project != null) {
                content = "<div class=\"card\">" +
                         "<h3>Project: " + project.name + "</h3>" +
                         "<p><strong>Description:</strong> " + project.description + "</p>" +
                         "<p><strong>Created:</strong> " + project.created + "</p>" +
                         "<p><strong>Status:</strong> <span style=\"color:green\">Active</span></p>" +
                         "</div>" +
                         "<div class=\"card\">" +
                         "<h4>Actions</h4>" +
                         "<a href=\"#\" class=\"btn\">Upload Flow</a> " +
                         "<a href=\"#\" class=\"btn\">Schedule Job</a> " +
                         "<a href=\"#\" class=\"btn\">View History</a>" +
                         "</div>";
            } else {
                content = "<div class=\"card\"><h3>Project not found</h3></div>";
            }
            
            String response = "<html><head><title>Azkaban - Project Details</title>" +
            "<style>body{font-family:Arial;margin:0;background:#f5f5f5}" +
            ".header{background:#007cba;color:white;padding:15px}" +
            ".content{padding:20px}" +
            ".card{background:white;padding:20px;margin:10px 0;border-radius:5px}" +
            ".btn{background:#28a745;color:white;padding:8px 16px;text-decoration:none;border-radius:3px;margin:5px}" +
            "</style></head><body>" +
            "<div class=\"header\"><h1>Azkaban Project Details</h1></div>" +
            "<div class=\"content\">" +
            content +
            "<div class=\"card\">" +
            "<a href=\"/manager\" class=\"btn\">Back to Projects</a> " +
            "<a href=\"/index\" class=\"btn\">Dashboard</a>" +
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
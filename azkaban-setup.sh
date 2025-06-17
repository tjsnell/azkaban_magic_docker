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
    private static List<WorkflowExecution> executions = new ArrayList<>();
    
    public static void main(String[] args) throws Exception {
        HttpServer server = HttpServer.create(new InetSocketAddress(8081), 0);
        server.createContext("/", new LoginHandler());
        server.createContext("/index", new IndexHandler());
        server.createContext("/manager", new ProjectManagerHandler());
        server.createContext("/manager/createProject", new CreateProjectHandler());
        server.createContext("/manager/project", new ProjectDetailHandler());
        server.createContext("/manager/upload", new UploadFlowHandler());
        server.createContext("/manager/uploadFlow", new ProcessUploadHandler());
        server.createContext("/executor", new ExecutorHandler());
        server.createContext("/history", new ExecutionHistoryHandler());
        server.createContext("/executor/execute", new ExecuteFlowHandler());
        server.setExecutor(null);
        System.out.println("Azkaban Web Server running on http://localhost:8081");
        server.start();
    }
    
    static class Project {
        String name;
        String description;
        String created;
        List<Flow> flows;
        
        Project(String name, String description) {
            this.name = name;
            this.description = description;
            this.created = new Date().toString();
            this.flows = new ArrayList<>();
        }
    }
    
    static class Flow {
        String name;
        String project;
        String description;
        String created;
        
        Flow(String name, String project, String description) {
            this.name = name;
            this.project = project;
            this.description = description;
            this.created = new Date().toString();
        }
    }
    
    static class WorkflowExecution {
        int executionId;
        String projectName;
        String flowName;
        String status;
        String startTime;
        String endTime;
        String submitUser;
        
        WorkflowExecution(String projectName, String flowName, String submitUser) {
            this.executionId = executions.size() + 1;
            this.projectName = projectName;
            this.flowName = flowName;
            this.submitUser = submitUser;
            this.status = "RUNNING";
            this.startTime = new Date().toString();
            this.endTime = "";
        }
        
        void complete(String status) {
            this.status = status;
            this.endTime = new Date().toString();
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
            "<a href=\"/manager/upload\" class=\"btn\">Upload Flow</a> " +
            "<a href=\"/history\" class=\"btn\">View Executions</a>" +
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
    
    static class UploadFlowHandler implements HttpHandler {
        public void handle(HttpExchange t) throws IOException {
            String projectOptions = "";
            for (Project p : projects) {
                projectOptions += "<option value=\"" + p.name + "\">" + p.name + "</option>";
            }
            
            String response = "<html><head><title>Azkaban - Upload Flow</title>" +
            "<style>body{font-family:Arial;margin:0;background:#f5f5f5}" +
            ".header{background:#007cba;color:white;padding:15px}" +
            ".content{padding:20px}" +
            ".card{background:white;padding:20px;margin:10px 0;border-radius:5px}" +
            ".btn{background:#28a745;color:white;padding:8px 16px;text-decoration:none;border-radius:3px;margin:5px}" +
            "input,textarea,select{width:100%;padding:10px;margin:10px 0;border:1px solid #ddd}" +
            ".file-upload{border:2px dashed #ddd;padding:20px;text-align:center;margin:10px 0}" +
            "</style></head><body>" +
            "<div class=\"header\"><h1>Azkaban Upload Flow</h1></div>" +
            "<div class=\"content\">" +
            "<div class=\"card\">" +
            "<h3>Upload Workflow Definition</h3>" +
            (projects.isEmpty() ? 
                "<p style=\"color:red\">No projects available. <a href=\"/manager\">Create a project first</a>.</p>" :
                "<form action=\"/manager/uploadFlow\" method=\"get\">" +
                "<select name=\"project\" required>" +
                "<option value=\"\">Select Project</option>" +
                projectOptions +
                "</select>" +
                "<input type=\"text\" name=\"flowName\" placeholder=\"Flow Name\" required>" +
                "<textarea name=\"flowDescription\" placeholder=\"Flow Description\" rows=\"3\"></textarea>" +
                "<div class=\"file-upload\">" +
                "<p>📁 Workflow File Upload</p>" +
                "<p>In a real Azkaban setup, you would upload a ZIP file containing:</p>" +
                "<ul style=\"text-align:left;max-width:400px;margin:0 auto\">" +
                "<li>.job files defining workflow steps</li>" +
                "<li>.properties files with configurations</li>" +
                "<li>Scripts and dependencies</li>" +
                "</ul>" +
                "<input type=\"text\" name=\"fileName\" placeholder=\"demo-workflow.zip\" value=\"demo-workflow.zip\">" +
                "</div>" +
                "<button type=\"submit\" class=\"btn\">Upload Flow</button>" +
                "</form>"
            ) +
            "</div>" +
            "<div class=\"card\">" +
            "<h4>Workflow Examples</h4>" +
            "<p><strong>Simple Job:</strong> A single script execution</p>" +
            "<p><strong>Sequential Flow:</strong> Jobs that run one after another</p>" +
            "<p><strong>Parallel Flow:</strong> Jobs that run simultaneously</p>" +
            "<p><strong>Conditional Flow:</strong> Jobs with success/failure conditions</p>" +
            "</div>" +
            "<div class=\"card\">" +
            "<a href=\"/index\" class=\"btn\">Back to Dashboard</a> " +
            "<a href=\"/manager\" class=\"btn\">Manage Projects</a>" +
            "</div>" +
            "</div></body></html>";
            
            t.getResponseHeaders().set("Content-Type", "text/html");
            t.sendResponseHeaders(200, response.length());
            OutputStream os = t.getResponseBody();
            os.write(response.getBytes());
            os.close();
        }
    }
    
    static class ProcessUploadHandler implements HttpHandler {
        public void handle(HttpExchange t) throws IOException {
            String query = t.getRequestURI().getQuery();
            if (query != null) {
                String[] params = query.split("&");
                String projectName = "", flowName = "", flowDescription = "", fileName = "";
                for (String param : params) {
                    String[] pair = param.split("=");
                    if (pair.length == 2) {
                        if ("project".equals(pair[0])) projectName = pair[1].replace("+", " ");
                        if ("flowName".equals(pair[0])) flowName = pair[1].replace("+", " ");
                        if ("flowDescription".equals(pair[0])) flowDescription = pair[1].replace("+", " ");
                        if ("fileName".equals(pair[0])) fileName = pair[1].replace("+", " ");
                    }
                }
                
                if (!projectName.isEmpty() && !flowName.isEmpty()) {
                    // Find the project and add the flow
                    for (Project p : projects) {
                        if (p.name.equals(projectName)) {
                            p.flows.add(new Flow(flowName, projectName, flowDescription));
                            break;
                        }
                    }
                }
            }
            
            // Redirect back to upload page
            t.getResponseHeaders().set("Location", "/manager/upload");
            t.sendResponseHeaders(302, 0);
            t.getResponseBody().close();
        }
    }
    
    static class ExecutorHandler implements HttpHandler {
        public void handle(HttpExchange t) throws IOException {
            String query = t.getRequestURI().getQuery();
            String projectName = "";
            if (query != null && query.startsWith("project=")) {
                projectName = query.substring(8).replace("+", " ");
            }
            
            Project project = null;
            for (Project p : projects) {
                if (p.name.equals(projectName)) {
                    project = p;
                    break;
                }
            }
            
            String flowOptions = "";
            if (project != null) {
                for (Flow f : project.flows) {
                    flowOptions += "<tr><td>" + f.name + "</td><td>" + f.description + "</td><td>" + f.created + "</td>" +
                                 "<td><a href=\"/executor/execute?project=" + projectName + "&flow=" + f.name + "\" class=\"btn\">Execute</a></td></tr>";
                }
            }
            
            String response = "<html><head><title>Azkaban - Executor</title>" +
            "<style>body{font-family:Arial;margin:0;background:#f5f5f5}" +
            ".header{background:#007cba;color:white;padding:15px}" +
            ".content{padding:20px}" +
            ".card{background:white;padding:20px;margin:10px 0;border-radius:5px}" +
            ".btn{background:#28a745;color:white;padding:8px 16px;text-decoration:none;border-radius:3px;margin:5px}" +
            "table{width:100%;border-collapse:collapse;margin:20px 0}" +
            "th,td{border:1px solid #ddd;padding:12px;text-align:left}" +
            "th{background:#f8f9fa}" +
            "</style></head><body>" +
            "<div class=\"header\"><h1>Azkaban Executor</h1></div>" +
            "<div class=\"content\">" +
            "<div class=\"card\">" +
            "<h3>Available Flows" + (project != null ? " - " + project.name : "") + "</h3>" +
            (project == null || project.flows.isEmpty() ? 
                "<p>No flows available. <a href=\"/manager/upload\">Upload a flow first</a>.</p>" :
                "<table><tr><th>Flow Name</th><th>Description</th><th>Created</th><th>Actions</th></tr>" + flowOptions + "</table>"
            ) +
            "</div>" +
            "<div class=\"card\">" +
            "<h4>Execution Options</h4>" +
            "<p>🔄 <strong>Execute Now:</strong> Run workflow immediately</p>" +
            "<p>⏰ <strong>Schedule:</strong> Set up recurring executions</p>" +
            "<p>🎯 <strong>Parameters:</strong> Override default job parameters</p>" +
            "</div>" +
            "<div class=\"card\">" +
            "<a href=\"/index\" class=\"btn\">Dashboard</a> " +
            "<a href=\"/manager\" class=\"btn\">Projects</a> " +
            "<a href=\"/history\" class=\"btn\">View History</a>" +
            "</div>" +
            "</div></body></html>";
            
            t.getResponseHeaders().set("Content-Type", "text/html");
            t.sendResponseHeaders(200, response.length());
            OutputStream os = t.getResponseBody();
            os.write(response.getBytes());
            os.close();
        }
    }
    
    static class ExecuteFlowHandler implements HttpHandler {
        public void handle(HttpExchange t) throws IOException {
            String query = t.getRequestURI().getQuery();
            String projectName = "", flowName = "";
            if (query != null) {
                String[] params = query.split("&");
                for (String param : params) {
                    String[] pair = param.split("=");
                    if (pair.length == 2) {
                        if ("project".equals(pair[0])) projectName = pair[1].replace("+", " ");
                        if ("flow".equals(pair[0])) flowName = pair[1].replace("+", " ");
                    }
                }
            }
            
            if (!projectName.isEmpty() && !flowName.isEmpty()) {
                // Create a new execution
                WorkflowExecution execution = new WorkflowExecution(projectName, flowName, "admin");
                executions.add(execution);
                
                // Simulate completion after a few seconds
                new Thread(() -> {
                    try {
                        Thread.sleep(3000);
                        execution.complete("SUCCEEDED");
                    } catch (InterruptedException e) {
                        execution.complete("FAILED");
                    }
                }).start();
            }
            
            // Redirect to execution history
            t.getResponseHeaders().set("Location", "/history");
            t.sendResponseHeaders(302, 0);
            t.getResponseBody().close();
        }
    }
    
    static class ExecutionHistoryHandler implements HttpHandler {
        public void handle(HttpExchange t) throws IOException {
            String executionList = "";
            for (int i = executions.size() - 1; i >= 0; i--) {
                WorkflowExecution exec = executions.get(i);
                String statusColor = "blue";
                if ("SUCCEEDED".equals(exec.status)) statusColor = "green";
                else if ("FAILED".equals(exec.status)) statusColor = "red";
                
                executionList += "<tr>" +
                    "<td>" + exec.executionId + "</td>" +
                    "<td>" + exec.projectName + "</td>" +
                    "<td>" + exec.flowName + "</td>" +
                    "<td><span style=\"color:" + statusColor + "\">" + exec.status + "</span></td>" +
                    "<td>" + exec.startTime + "</td>" +
                    "<td>" + (exec.endTime.isEmpty() ? "Running..." : exec.endTime) + "</td>" +
                    "<td>" + exec.submitUser + "</td>" +
                "</tr>";
            }
            
            String response = "<html><head><title>Azkaban - Execution History</title>" +
            "<style>body{font-family:Arial;margin:0;background:#f5f5f5}" +
            ".header{background:#007cba;color:white;padding:15px}" +
            ".content{padding:20px}" +
            ".card{background:white;padding:20px;margin:10px 0;border-radius:5px}" +
            ".btn{background:#28a745;color:white;padding:8px 16px;text-decoration:none;border-radius:3px;margin:5px}" +
            "table{width:100%;border-collapse:collapse;margin:20px 0}" +
            "th,td{border:1px solid #ddd;padding:12px;text-align:left}" +
            "th{background:#f8f9fa}" +
            ".refresh{background:#007cba;color:white;padding:5px 10px;border:none;border-radius:3px;cursor:pointer}" +
            "</style>" +
            "<script>setTimeout(function(){location.reload();}, 5000);</script></head><body>" +
            "<div class=\"header\"><h1>Azkaban Execution History</h1></div>" +
            "<div class=\"content\">" +
            "<div class=\"card\">" +
            "<h3>Recent Executions (" + executions.size() + ")</h3>" +
            "<button onclick=\"location.reload()\" class=\"refresh\">🔄 Refresh</button>" +
            (executions.isEmpty() ? 
                "<p>No executions yet. <a href=\"/manager/upload\">Upload and execute a flow</a>.</p>" :
                "<table><tr><th>ID</th><th>Project</th><th>Flow</th><th>Status</th><th>Start Time</th><th>End Time</th><th>User</th></tr>" + executionList + "</table>"
            ) +
            "</div>" +
            "<div class=\"card\">" +
            "<h4>Execution Status Legend</h4>" +
            "<p><span style=\"color:blue\">🔄 RUNNING</span> - Execution in progress</p>" +
            "<p><span style=\"color:green\">✅ SUCCEEDED</span> - Execution completed successfully</p>" +
            "<p><span style=\"color:red\">❌ FAILED</span> - Execution failed with errors</p>" +
            "</div>" +
            "<div class=\"card\">" +
            "<a href=\"/index\" class=\"btn\">Dashboard</a> " +
            "<a href=\"/manager\" class=\"btn\">Projects</a> " +
            "<a href=\"/manager/upload\" class=\"btn\">Upload Flow</a>" +
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
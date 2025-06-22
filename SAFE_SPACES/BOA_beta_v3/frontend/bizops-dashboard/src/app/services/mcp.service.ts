import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, Subject, BehaviorSubject } from 'rxjs';
import { webSocket, WebSocketSubject } from 'rxjs/webSocket';

export interface MCPRequest {
  agent_id: string;
  action: string;
  parameters: any;
  session_id?: string;
  request_id?: string;
}

export interface MCPResponse {
  status: string;
  data: any;
  agent_id: string;
  session_id: string;
  request_id?: string;
  timestamp: string;
  error?: string;
}

export interface Agent {
  agent_id: string;
  name: string;
  status: any;
  available_actions: string[];
}

export interface Tool {
  tool_id: string;
  name: string;
  description: string;
  parameters: any[];
}

export interface SystemStatus {
  total_agents: number;
  total_tools: number;
  active_sessions: number;
  agents: any[];
  tools: string[];
}

@Injectable({
  providedIn: 'root'
})
export class MCPService {
  private apiUrl = 'http://127.0.0.1:8000';
  private wsUrl = 'ws://127.0.0.1:8000/mcp/ws';
  private wsSubject?: WebSocketSubject<MCPResponse>;
  private sessionId = this.generateSessionId();
  private connectionStatus = new BehaviorSubject<boolean>(false);

  constructor(private http: HttpClient) {}

  // HTTP-based MCP requests
  sendRequest(request: MCPRequest): Observable<MCPResponse> {
    return this.http.post<MCPResponse>(`${this.apiUrl}/mcp/request`, request);
  }

  // WebSocket-based real-time communication
  connectWebSocket(): Observable<MCPResponse> {
    this.wsSubject = webSocket(`${this.wsUrl}/${this.sessionId}`);
    this.connectionStatus.next(true);
    return this.wsSubject.asObservable();
  }

  sendWebSocketRequest(request: MCPRequest): void {
    if (this.wsSubject) {
      this.wsSubject.next(request);
    }
  }

  disconnectWebSocket(): void {
    if (this.wsSubject) {
      this.wsSubject.complete();
      this.connectionStatus.next(false);
    }
  }

  getConnectionStatus(): Observable<boolean> {
    return this.connectionStatus.asObservable();
  }

  // System information
  getSystemStatus(): Observable<SystemStatus> {
    return this.http.get<SystemStatus>(`${this.apiUrl}/system/status`);
  }

  getAgents(): Observable<{ agents: Agent[] }> {
    return this.http.get<{ agents: Agent[] }>(`${this.apiUrl}/agents`);
  }

  getTools(): Observable<{ tools: Tool[] }> {
    return this.http.get<{ tools: Tool[] }>(`${this.apiUrl}/tools`);
  }

  getHealth(): Observable<any> {
    return this.http.get(`${this.apiUrl}/health`);
  }

  // Session management
  getSessions(): Observable<any> {
    return this.http.get(`${this.apiUrl}/sessions`);
  }

  getSession(sessionId: string): Observable<any> {
    return this.http.get(`${this.apiUrl}/sessions/${sessionId}`);
  }

  cleanupSession(sessionId: string): Observable<any> {
    return this.http.delete(`${this.apiUrl}/sessions/${sessionId}`);
  }

  // Convenience methods for specific agents

  // Compliance Agent
  analyzeCompliance(planJson: string, userMessage?: string): Observable<MCPResponse> {
    return this.sendRequest({
      agent_id: 'compliance_agent',
      action: 'analyze_compliance',
      parameters: {
        plan_json: planJson,
        user_message: userMessage
      },
      session_id: this.sessionId
    });
  }

  generateComplianceReport(analysisFile: string, reportType: string = 'compliance_report'): Observable<MCPResponse> {
    return this.sendRequest({
      agent_id: 'compliance_agent',
      action: 'generate_report',
      parameters: {
        analysis_file: analysisFile,
        report_type: reportType
      },
      session_id: this.sessionId
    });
  }

  getComplianceStatus(): Observable<MCPResponse> {
    return this.sendRequest({
      agent_id: 'compliance_agent',
      action: 'get_compliance_status',
      parameters: {},
      session_id: this.sessionId
    });
  }

  // Security Agent
  auditSecurity(planJson: string, securityFramework: string = 'CIS'): Observable<MCPResponse> {
    return this.sendRequest({
      agent_id: 'security_agent',
      action: 'audit_security',
      parameters: {
        plan_json: planJson,
        security_framework: securityFramework
      },
      session_id: this.sessionId
    });
  }

  analyzeSecrets(planJson: string): Observable<MCPResponse> {
    return this.sendRequest({
      agent_id: 'security_agent',
      action: 'analyze_secrets',
      parameters: {
        plan_json: planJson
      },
      session_id: this.sessionId
    });
  }

  checkEncryption(planJson: string): Observable<MCPResponse> {
    return this.sendRequest({
      agent_id: 'security_agent',
      action: 'check_encryption',
      parameters: {
        plan_json: planJson
      },
      session_id: this.sessionId
    });
  }

  getSecurityStatus(): Observable<MCPResponse> {
    return this.sendRequest({
      agent_id: 'security_agent',
      action: 'get_security_status',
      parameters: {},
      session_id: this.sessionId
    });
  }

  // Cost Agent
  analyzeCosts(planJson: string, region: string = 'us-east-1'): Observable<MCPResponse> {
    return this.sendRequest({
      agent_id: 'cost_agent',
      action: 'analyze_costs',
      parameters: {
        plan_json: planJson,
        region: region
      },
      session_id: this.sessionId
    });
  }

  optimizeCosts(planJson: string, region: string = 'us-east-1'): Observable<MCPResponse> {
    return this.sendRequest({
      agent_id: 'cost_agent',
      action: 'optimize_costs',
      parameters: {
        plan_json: planJson,
        region: region
      },
      session_id: this.sessionId
    });
  }

  getCostStatus(): Observable<MCPResponse> {
    return this.sendRequest({
      agent_id: 'cost_agent',
      action: 'get_cost_status',
      parameters: {},
      session_id: this.sessionId
    });
  }

  // Legacy RAG compatibility
  callRAG(payload: any): Observable<any> {
    return this.http.post(`${this.apiUrl}/rag`, payload);
  }

  // Utility methods
  private generateSessionId(): string {
    return `session_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }

  getSessionId(): string {
    return this.sessionId;
  }

  // Error handling
  private handleError(error: any): Observable<never> {
    console.error('MCP Service Error:', error);
    return new Observable(observer => {
      observer.error(error.message || 'An error occurred in MCP service');
    });
  }
}

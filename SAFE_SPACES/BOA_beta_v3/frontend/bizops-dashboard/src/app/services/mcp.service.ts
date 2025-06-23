import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, Subject, BehaviorSubject } from 'rxjs';
import { webSocket, WebSocketSubject } from 'rxjs/webSocket';
import { MCPRequest, MCPResponse } from '../models/mcp';
import { apiBaseUrl } from '../app.config';

export type { MCPRequest, MCPResponse };

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
  // Use a configurable API base URL for backend API calls
  // To switch between FastAPI and n8n, change apiBaseUrl in app.config.ts
  private apiBaseUrl = apiBaseUrl;

  // The WebSocket URL remains the same, pointing to the backend for real-time updates.
  private wsUrl = 'ws://localhost:8000/mcp/ws';
  private wsSubject?: WebSocketSubject<any>;
  private sessionId = this.generateSessionId();
  private connectionStatus = new BehaviorSubject<boolean>(false);

  constructor(private http: HttpClient) {}

  /**
   * Sends a request to the n8n orchestration webhook.
   * The n8n workflow will then call the appropriate backend agent(s).
   * @param agent The target agent (e.g., 'compliance', 'security', 'cost')
   * @param action The action for the agent to perform
   * @param parameters The data to send to the agent
   * @returns An observable with the analysis result
   */
  private analyze(agent: string, action: string, parameters: any): Observable<MCPResponse> {
    const requestBody: MCPRequest = {
      agent_id: `${agent}_agent`,
      action: action,
      parameters: parameters,
      session_id: this.sessionId
    };
    // In a real n8n setup, you might POST the agent/action/params
    // and let n8n build the final request to the backend.
    // For now, we'll send a structured object that n8n can easily forward.
    return this.http.post<MCPResponse>(`${this.apiBaseUrl}/${agent}/analyze`, requestBody);
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
    return this.http.get<SystemStatus>(`${this.apiBaseUrl}/system/status`);
  }

  getAgents(): Observable<{ agents: Agent[] }> {
    return this.http.get<{ agents: Agent[] }>(`${this.apiBaseUrl}/agents`);
  }

  getTools(): Observable<{ tools: Tool[] }> {
    return this.http.get<{ tools: Tool[] }>(`${this.apiBaseUrl}/tools`);
  }

  getHealth(): Observable<any> {
    return this.http.get(`${this.apiBaseUrl}/health`);
  }

  // Session management
  getSessions(): Observable<any> {
    return this.http.get(`${this.apiBaseUrl}/sessions`);
  }

  getSession(sessionId: string): Observable<any> {
    return this.http.get(`${this.apiBaseUrl}/sessions/${sessionId}`);
  }

  cleanupSession(sessionId: string): Observable<any> {
    return this.http.delete(`${this.apiBaseUrl}/sessions/${sessionId}`);
  }

  // Convenience methods for specific agents

  // Compliance Agent
  analyzeCompliance(planJson: string, userMessage?: string): Observable<MCPResponse> {
    const body = {
      agent_id: 'compliance_agent',
      action: 'analyze_compliance',
      parameters: { plan_json: planJson, user_message: userMessage },
      session_id: this.sessionId
    };
    return this.http.post<MCPResponse>(`${this.apiBaseUrl}/compliance/analyze`, body);
  }

  generateComplianceReport(analysisFile: string, reportType: string = 'compliance_report'): Observable<MCPResponse> {
    const body = {
      agent_id: 'compliance_agent',
      action: 'generate_report',
      parameters: { analysis_file: analysisFile, report_type: reportType },
      session_id: this.sessionId
    };
    return this.http.post<MCPResponse>(`${this.apiBaseUrl}/compliance/analyze`, body);
  }

  getComplianceStatus(): Observable<MCPResponse> {
    const body = {
      agent_id: 'compliance_agent',
      action: 'get_compliance_status',
      parameters: {},
      session_id: this.sessionId
    };
    return this.http.post<MCPResponse>(`${this.apiBaseUrl}/compliance/analyze`, body);
  }

  // Security Agent
  auditSecurity(planJson: string, securityFramework: string = 'CIS'): Observable<MCPResponse> {
    const body = {
      agent_id: 'security_agent',
      action: 'audit_security',
      parameters: { plan_json: planJson, security_framework: securityFramework },
      session_id: this.sessionId
    };
    return this.http.post<MCPResponse>(`${this.apiBaseUrl}/security/audit`, body);
  }

  analyzeSecrets(planJson: string): Observable<MCPResponse> {
    const body = {
      agent_id: 'security_agent',
      action: 'analyze_secrets',
      parameters: { plan_json: planJson },
      session_id: this.sessionId
    };
    return this.http.post<MCPResponse>(`${this.apiBaseUrl}/security/audit`, body);
  }

  checkEncryption(planJson: string): Observable<MCPResponse> {
    const body = {
      agent_id: 'security_agent',
      action: 'check_encryption',
      parameters: { plan_json: planJson },
      session_id: this.sessionId
    };
    return this.http.post<MCPResponse>(`${this.apiBaseUrl}/security/audit`, body);
  }

  getSecurityStatus(): Observable<MCPResponse> {
    const body = {
      agent_id: 'security_agent',
      action: 'get_security_status',
      parameters: {},
      session_id: this.sessionId
    };
    return this.http.post<MCPResponse>(`${this.apiBaseUrl}/security/audit`, body);
  }

  // Cost Agent
  analyzeCosts(planJson: string, region: string = 'us-east-1'): Observable<MCPResponse> {
    const body = {
      agent_id: 'cost_agent',
      action: 'analyze_costs',
      parameters: { plan_json: planJson, region: region },
      session_id: this.sessionId
    };
    return this.http.post<MCPResponse>(`${this.apiBaseUrl}/costs/analyze`, body);
  }

  optimizeCosts(planJson: string, region: string = 'us-east-1'): Observable<MCPResponse> {
    const body = {
      agent_id: 'cost_agent',
      action: 'optimize_costs',
      parameters: { plan_json: planJson, region: region },
      session_id: this.sessionId
    };
    return this.http.post<MCPResponse>(`${this.apiBaseUrl}/costs/analyze`, body);
  }

  getCostStatus(): Observable<MCPResponse> {
    const body = {
      agent_id: 'cost_agent',
      action: 'get_cost_status',
      parameters: {},
      session_id: this.sessionId
    };
    return this.http.post<MCPResponse>(`${this.apiBaseUrl}/costs/analyze`, body);
  }

  // Legacy RAG compatibility
  callRAG(payload: any): Observable<any> {
    return this.http.post(`${this.apiBaseUrl}/rag`, payload);
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

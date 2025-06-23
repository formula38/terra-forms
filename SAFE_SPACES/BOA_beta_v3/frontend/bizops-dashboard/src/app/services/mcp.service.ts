import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, Subject, BehaviorSubject } from 'rxjs';
import { webSocket, WebSocketSubject } from 'rxjs/webSocket';
import { MCPRequest, MCPResponse } from '../models/mcp';

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
  // The base URL for the n8n webhook, which will orchestrate the calls to the backend.
  // This should match the webhook URL you create in your n8n instance.
  private n8nWebhookUrl = 'http://localhost:5678/webhook/bizops-analysis';

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
    return this.http.post<MCPResponse>(this.n8nWebhookUrl, requestBody);
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
    return this.http.get<SystemStatus>(`${this.n8nWebhookUrl}/system/status`);
  }

  getAgents(): Observable<{ agents: Agent[] }> {
    return this.http.get<{ agents: Agent[] }>(`${this.n8nWebhookUrl}/agents`);
  }

  getTools(): Observable<{ tools: Tool[] }> {
    return this.http.get<{ tools: Tool[] }>(`${this.n8nWebhookUrl}/tools`);
  }

  getHealth(): Observable<any> {
    return this.http.get(`${this.n8nWebhookUrl}/health`);
  }

  // Session management
  getSessions(): Observable<any> {
    return this.http.get(`${this.n8nWebhookUrl}/sessions`);
  }

  getSession(sessionId: string): Observable<any> {
    return this.http.get(`${this.n8nWebhookUrl}/sessions/${sessionId}`);
  }

  cleanupSession(sessionId: string): Observable<any> {
    return this.http.delete(`${this.n8nWebhookUrl}/sessions/${sessionId}`);
  }

  // Convenience methods for specific agents

  // Compliance Agent
  analyzeCompliance(planJson: string, userMessage?: string): Observable<MCPResponse> {
    return this.analyze('compliance', 'analyze_compliance', { plan_json: planJson, user_message: userMessage });
  }

  generateComplianceReport(analysisFile: string, reportType: string = 'compliance_report'): Observable<MCPResponse> {
    return this.analyze('compliance', 'generate_report', { analysis_file: analysisFile, report_type: reportType });
  }

  getComplianceStatus(): Observable<MCPResponse> {
    return this.analyze('compliance', 'get_compliance_status', {});
  }

  // Security Agent
  auditSecurity(planJson: string, securityFramework: string = 'CIS'): Observable<MCPResponse> {
    return this.analyze('security', 'audit_security', { plan_json: planJson, security_framework: securityFramework });
  }

  analyzeSecrets(planJson: string): Observable<MCPResponse> {
    return this.analyze('security', 'analyze_secrets', { plan_json: planJson });
  }

  checkEncryption(planJson: string): Observable<MCPResponse> {
    return this.analyze('security', 'check_encryption', { plan_json: planJson });
  }

  getSecurityStatus(): Observable<MCPResponse> {
    return this.analyze('security', 'get_security_status', {});
  }

  // Cost Agent
  analyzeCosts(planJson: string, region: string = 'us-east-1'): Observable<MCPResponse> {
    return this.analyze('cost', 'analyze_costs', { plan_json: planJson, region: region });
  }

  optimizeCosts(planJson: string, region: string = 'us-east-1'): Observable<MCPResponse> {
    return this.analyze('cost', 'optimize_costs', { plan_json: planJson, region: region });
  }

  getCostStatus(): Observable<MCPResponse> {
    return this.analyze('cost', 'get_cost_status', {});
  }

  // Legacy RAG compatibility
  callRAG(payload: any): Observable<any> {
    return this.http.post(`${this.n8nWebhookUrl}/rag`, payload);
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

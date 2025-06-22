// src/app/services/rag.service.ts
import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable, throwError } from 'rxjs';
import { catchError, map } from 'rxjs/operators';
import { ChatMessage } from '../models/chat-message.interface';
import { MCPService, MCPResponse } from './mcp.service';

export interface RAGRequest {
  plan_json: string;
  output_path: string;
  refdir?: string;
  user_message?: string;
}

export interface RAGResponse {
  message: string;
  plan_json: string;
  output_path: string;
  refdir?: string;
  analysis?: any;
  compliance_violations?: any[];
}

@Injectable({
  providedIn: 'root',
})
export class RagService {
  private apiUrl = 'http://127.0.0.1:8000';

  constructor(
    private http: HttpClient,
    private mcpService: MCPService
  ) {}

  // Legacy method - now uses MCP under the hood
  callRAG(payload: RAGRequest): Observable<RAGResponse> {
    // Use the new MCP service for compliance analysis
    return this.mcpService.analyzeCompliance(
      payload.plan_json,
      payload.user_message
    ).pipe(
      map((mcpResponse: MCPResponse) => {
        // Convert MCP response to legacy RAG response format
        const result = mcpResponse.data;
        return {
          message: result.message || 'Analysis completed',
          plan_json: payload.plan_json,
          output_path: payload.output_path,
          refdir: payload.refdir,
          analysis: {
            timestamp: mcpResponse.timestamp,
            total_violations: result.total_violations || 0,
            severity_breakdown: {
              high: 0,
              medium: 0,
              low: 0
            }
          },
          compliance_violations: []
        };
      }),
      catchError(this.handleError)
    );
  }

  // Enhanced method using MCP
  sendChatMessage(message: string, metadata?: any): Observable<ChatMessage> {
    const planJson = metadata?.plan_json || 'infra/terraform/tfplan.json';

    // Use MCP compliance agent for analysis
    return this.mcpService.analyzeCompliance(planJson, message).pipe(
      map((mcpResponse: MCPResponse) => {
        const result = mcpResponse.data;

        return {
          id: this.generateId(),
          content: result.message || 'Analysis completed',
          sender: 'bot' as const,
          timestamp: new Date(),
          status: 'sent' as const,
          metadata: {
            analysis: result,
            compliance_violations: result.compliance_violations || [],
            agent_id: mcpResponse.agent_id,
            session_id: mcpResponse.session_id
          }
        };
      }),
      catchError(this.handleError)
    );
  }

  // New methods for different types of analysis

  // Security analysis
  analyzeSecurity(planJson: string, securityFramework: string = 'CIS'): Observable<ChatMessage> {
    return this.mcpService.auditSecurity(planJson, securityFramework).pipe(
      map((mcpResponse: MCPResponse) => {
        const result = mcpResponse.data;

        return {
          id: this.generateId(),
          content: `Security audit completed. Found ${result.total_findings} security findings, including ${result.high_risk_count} high-risk issues.`,
          sender: 'bot' as const,
          timestamp: new Date(),
          status: 'sent' as const,
          metadata: {
            security_audit: result,
            agent_id: mcpResponse.agent_id,
            session_id: mcpResponse.session_id
          }
        };
      }),
      catchError(this.handleError)
    );
  }

  // Cost analysis
  analyzeCosts(planJson: string, region: string = 'us-east-1'): Observable<ChatMessage> {
    return this.mcpService.analyzeCosts(planJson, region).pipe(
      map((mcpResponse: MCPResponse) => {
        const result = mcpResponse.data;

        return {
          id: this.generateId(),
          content: `Cost analysis completed. Estimated monthly cost: $${result.total_monthly_cost.toFixed(2)}.`,
          sender: 'bot' as const,
          timestamp: new Date(),
          status: 'sent' as const,
          metadata: {
            cost_analysis: result,
            agent_id: mcpResponse.agent_id,
            session_id: mcpResponse.session_id
          }
        };
      }),
      catchError(this.handleError)
    );
  }

  // Cost optimization
  optimizeCosts(planJson: string, region: string = 'us-east-1'): Observable<ChatMessage> {
    return this.mcpService.optimizeCosts(planJson, region).pipe(
      map((mcpResponse: MCPResponse) => {
        const result = mcpResponse.data;

        return {
          id: this.generateId(),
          content: `Cost optimization analysis completed. Potential monthly savings: $${result.potential_monthly_savings.toFixed(2)} (${result.savings_percentage.toFixed(1)}%).`,
          sender: 'bot' as const,
          timestamp: new Date(),
          status: 'sent' as const,
          metadata: {
            cost_optimization: result,
            agent_id: mcpResponse.agent_id,
            session_id: mcpResponse.session_id
          }
        };
      }),
      catchError(this.handleError)
    );
  }

  // Secrets analysis
  analyzeSecrets(planJson: string): Observable<ChatMessage> {
    return this.mcpService.analyzeSecrets(planJson).pipe(
      map((mcpResponse: MCPResponse) => {
        const result = mcpResponse.data;

        return {
          id: this.generateId(),
          content: `Secrets analysis completed. Found ${result.total_secrets} potential secrets, including ${result.high_risk_secrets} high-risk items.`,
          sender: 'bot' as const,
          timestamp: new Date(),
          status: 'sent' as const,
          metadata: {
            secrets_analysis: result,
            agent_id: mcpResponse.agent_id,
            session_id: mcpResponse.session_id
          }
        };
      }),
      catchError(this.handleError)
    );
  }

  // Encryption check
  checkEncryption(planJson: string): Observable<ChatMessage> {
    return this.mcpService.checkEncryption(planJson).pipe(
      map((mcpResponse: MCPResponse) => {
        const result = mcpResponse.data;
        const encryptionStatus = result.encryption_status;

        return {
        id: this.generateId(),
          content: `Encryption check completed. Status: ${encryptionStatus.encryption_compliance}. Found ${encryptionStatus.encryption_issues} encryption issues.`,
        sender: 'bot' as const,
        timestamp: new Date(),
        status: 'sent' as const,
        metadata: {
            encryption_check: result,
            agent_id: mcpResponse.agent_id,
            session_id: mcpResponse.session_id
          }
        };
      }),
      catchError(this.handleError)
    );
  }

  // Get system status
  getSystemStatus(): Observable<any> {
    return this.mcpService.getSystemStatus();
  }

  // Get available agents
  getAgents(): Observable<any> {
    return this.mcpService.getAgents();
  }

  // Get available tools
  getTools(): Observable<any> {
    return this.mcpService.getTools();
  }

  // Get compliance status
  getComplianceStatus(): Observable<any> {
    return this.mcpService.getComplianceStatus();
  }

  // Get security status
  getSecurityStatus(): Observable<any> {
    return this.mcpService.getSecurityStatus();
  }

  // Get cost status
  getCostStatus(): Observable<any> {
    return this.mcpService.getCostStatus();
  }

  private handleError(error: any) {
    console.error('RAG Service Error:', error);
    return throwError(() => new Error(error.message || 'An error occurred'));
  }

  private generateId(): string {
    return Date.now().toString(36) + Math.random().toString(36).substr(2);
  }
}

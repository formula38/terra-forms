// src/app/services/rag.service.ts
import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable, throwError } from 'rxjs';
import { catchError, map } from 'rxjs/operators';
import { ChatMessage } from '../models/chat-message.interface';

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

  constructor(private http: HttpClient) {}

  callRAG(payload: RAGRequest): Observable<RAGResponse> {
    return this.http.post<RAGResponse>(`${this.apiUrl}/rag`, payload).pipe(
      catchError(this.handleError)
    );
  }

  sendChatMessage(message: string, metadata?: any): Observable<ChatMessage> {
    const payload: RAGRequest = {
      plan_json: metadata?.plan_json || 'infra/terraform/tfplan.json',
      output_path: metadata?.output_path || 'output/findings/compliance_violations.json',
      refdir: metadata?.refdir || '/mnt/f/Cybersecurity Engineering/coldchainsecure/cold_rag',
      user_message: message
    };

    return this.callRAG(payload).pipe(
      map(response => ({
        id: this.generateId(),
        content: response.message || 'Analysis completed',
        sender: 'bot' as const,
        timestamp: new Date(),
        status: 'sent' as const,
        metadata: {
          analysis: response.analysis,
          compliance_violations: response.compliance_violations
        }
      }))
    );
  }

  private handleError(error: any) {
    console.error('RAG Service Error:', error);
    return throwError(() => new Error(error.message || 'An error occurred'));
  }

  private generateId(): string {
    return Date.now().toString(36) + Math.random().toString(36).substr(2);
  }
}

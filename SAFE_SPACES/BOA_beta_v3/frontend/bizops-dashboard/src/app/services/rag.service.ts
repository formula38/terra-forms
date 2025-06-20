// src/app/services/rag.service.ts
import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';

@Injectable({
  providedIn: 'root',
})
export class RagService {
  private apiUrl = 'http://127.0.0.1:8000/rag';

  constructor(private http: HttpClient) {}

  callRAG(payload: { plan_json: string; output_path: string; refdir?: string }): Observable<any> {
    return this.http.post(this.apiUrl, payload);
  }
}

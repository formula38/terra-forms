import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';

@Injectable({ providedIn: 'root' })
export class RagService {
  private apiUrl = '/api/rag';

  constructor(private http: HttpClient) {}

  runRAG(plan_json: string, output_path: string, refdir?: string): Observable<any> {
    return this.http.post(this.apiUrl, {
      plan_json,
      output_path,
      refdir
    });
  }
}

import { Component } from '@angular/core';
import { RagService } from './services/rag.service';

@Component({
  selector: 'app-root',
  templateUrl: './app.component.html'
})
export class AppComponent {
  constructor(private ragService: RagService) {}

  callRAG() {
    this.ragService.runRAG('infra/terraform/tfplan.json', 'output/findings/compliance_violations.json', 'reference_docs')
      .subscribe({
        next: res => console.log('✅ RAG Response:', res),
        error: err => console.error('❌ RAG Error:', err)
      });
  }
}

// src/app/components/rag-chat/rag-chat.component.ts
import { Component } from '@angular/core';
import { RagService } from '../../services/rag.service';

@Component({
  selector: 'rag-chat',
  standalone: true,
  templateUrl: './rag-chat.component.html',
  styleUrls: ['./rag-chat.component.scss'],
  imports: [], // Add HttpClientModule or FormsModule here if needed
})
export class RagChatComponent {
  constructor(private ragService: RagService) {}

  callRAG() {
    const payload = {
      plan_json: 'infra/terraform/tfplan.json',
      output_path: 'output/findings/compliance_violations.json',
      refdir: '/mnt/f/Cybersecurity Engineering/coldchainsecure/cold_rag',
    };

    this.ragService.callRAG(payload).subscribe({
      next: (res) => console.log('✅ Response:', res),
      error: (err) => console.error('❌ Error:', err),
    });
  }
}

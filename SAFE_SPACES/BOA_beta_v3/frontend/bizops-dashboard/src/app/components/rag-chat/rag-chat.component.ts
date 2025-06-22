// src/app/components/rag-chat/rag-chat.component.ts
import { Component, OnInit, ViewChild, ElementRef, AfterViewChecked } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { CommonModule } from '@angular/common';
import { RagService } from '../../services/rag.service';
import { ChatMessage } from '../../models/chat-message.interface';

interface QuickAction {
  label: string;
  message: string;
}

@Component({
  selector: 'rag-chat',
  standalone: true,
  templateUrl: './rag-chat.component.html',
  styleUrls: ['./rag-chat.component.scss'],
  imports: [CommonModule, FormsModule],
})
export class RagChatComponent implements OnInit, AfterViewChecked {
  @ViewChild('messageContainer') messageContainer!: ElementRef;

  messages: ChatMessage[] = [];
  currentMessage: string = '';
  isLoading: boolean = false;

  quickActions: QuickAction[] = [
    { label: '🔍 Analyze Compliance', message: 'Please analyze my Terraform configuration for compliance violations.' },
    { label: '🛡️ Security Check', message: 'Check my infrastructure for security vulnerabilities.' },
    { label: '📋 Generate Report', message: 'Generate a compliance report for my Terraform configuration.' },
    { label: '❓ Help', message: 'What can you help me with regarding Terraform compliance?' }
  ];

  constructor(private ragService: RagService) {}

  ngOnInit() {
    // Add welcome message
    this.addBotMessage('Hello! I\'m your Terraform Compliance Assistant. I can help you analyze your infrastructure for compliance violations, security issues, and generate reports. How can I assist you today?');
  }

  ngAfterViewChecked() {
    this.scrollToBottom();
  }

  sendMessage() {
    if (!this.currentMessage.trim() || this.isLoading) return;

    const userMessage: ChatMessage = {
      id: this.generateId(),
      content: this.currentMessage,
      sender: 'user',
      timestamp: new Date(),
      status: 'sent'
    };

    this.messages.push(userMessage);
    const messageToSend = this.currentMessage;
    this.currentMessage = '';
    this.isLoading = true;

    this.ragService.sendChatMessage(messageToSend).subscribe({
      next: (response) => {
        this.messages.push(response);
        this.isLoading = false;
      },
      error: (error) => {
        console.error('Error sending message:', error);
        this.addBotMessage('Sorry, I encountered an error while processing your request. Please try again.');
        this.isLoading = false;
      }
    });
  }

  sendQuickMessage(message: string) {
    this.currentMessage = message;
    this.sendMessage();
  }

  private addBotMessage(content: string) {
    const botMessage: ChatMessage = {
      id: this.generateId(),
      content,
      sender: 'bot',
      timestamp: new Date(),
      status: 'sent'
    };
    this.messages.push(botMessage);
  }

  private scrollToBottom(): void {
    try {
      this.messageContainer.nativeElement.scrollTop = this.messageContainer.nativeElement.scrollHeight;
    } catch (err) {
      console.error('Error scrolling to bottom:', err);
    }
  }

  private generateId(): string {
    return Date.now().toString(36) + Math.random().toString(36).substr(2);
  }

  // Helper method to safely get compliance violations
  getComplianceViolations(message: ChatMessage): any[] {
    return message.metadata?.compliance_violations || [];
  }

  // Legacy method for backward compatibility
  callRAG() {
    this.sendQuickMessage('Please analyze my Terraform configuration for compliance violations.');
  }
}

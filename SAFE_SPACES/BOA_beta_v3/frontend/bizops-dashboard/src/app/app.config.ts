import { ApplicationConfig, provideZoneChangeDetection } from '@angular/core';
import { provideRouter } from '@angular/router';
import { provideHttpClient } from '@angular/common/http';

import { routes } from './app.routes';
import { provideClientHydration, withEventReplay } from '@angular/platform-browser';

// Backend API base URL for all MCPService calls
// Switch between FastAPI (via Angular proxy) and n8n by changing this value:
// For FastAPI direct: '/api'
// For n8n orchestrator: 'http://localhost:5678/webhook/bizops-analysis'
export const apiBaseUrl = '/api';
// export const apiBaseUrl = 'http://localhost:5678/webhook/bizops-analysis';

export const appConfig: ApplicationConfig = {
  providers: [
    provideZoneChangeDetection({ eventCoalescing: true }),
    provideRouter(routes),
    provideClientHydration(withEventReplay()),
    provideHttpClient()
  ]
};

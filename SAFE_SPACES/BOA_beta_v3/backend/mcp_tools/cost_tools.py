#!/usr/bin/env python3
"""MCP Tools for Cost Analysis"""

import json
import asyncio
from pathlib import Path
from typing import Dict, List, Any, Optional
from datetime import datetime

from mcp_server_legacy import Tool, ToolParameter

class CostAnalyzerTool(Tool):
    """Analyze infrastructure costs from Terraform configurations"""
    
    def __init__(self):
        super().__init__(
            tool_id="cost_analyzer",
            name="Infrastructure Cost Analyzer",
            description="Estimate infrastructure costs from Terraform configurations",
            parameters=[
                {"name": "plan_json", "type": "string", "required": True, "description": "Path to Terraform plan JSON file"},
                {"name": "region", "type": "string", "required": False, "description": "AWS region for pricing", "default": "us-east-1"},
                {"name": "include_estimate", "type": "boolean", "required": False, "description": "Include cost estimates", "default": True}
            ],
            invoke_func=self._analyze_costs
        )
    
    async def _analyze_costs(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """Analyze infrastructure costs"""
        try:
            plan_json = params["plan_json"]
            region = params.get("region", "us-east-1")
            include_estimate = params.get("include_estimate", True)
            
            # Load Terraform plan
            with open(plan_json, 'r') as f:
                plan_data = json.load(f)
            
            # Extract resource information
            resources = self._extract_resources(plan_data)
            
            # Calculate cost estimates
            cost_analysis = {
                "region": region,
                "total_estimated_monthly_cost": 0.0,
                "resource_costs": [],
                "cost_breakdown": {
                    "compute": 0.0,
                    "storage": 0.0,
                    "network": 0.0,
                    "database": 0.0,
                    "other": 0.0
                }
            }
            
            if include_estimate:
                for resource in resources:
                    cost_estimate = self._estimate_resource_cost(resource, region)
                    cost_analysis["resource_costs"].append(cost_estimate)
                    cost_analysis["total_estimated_monthly_cost"] += cost_estimate.get("monthly_cost", 0.0)
                    
                    # Update cost breakdown
                    category = cost_estimate.get("category", "other")
                    if category in cost_analysis["cost_breakdown"]:
                        cost_analysis["cost_breakdown"][category] += cost_estimate.get("monthly_cost", 0.0)
            
            return {
                "cost_analysis_status": "completed",
                "analysis": cost_analysis,
                "timestamp": datetime.now().isoformat()
            }
            
        except Exception as e:
            return {
                "cost_analysis_status": "error",
                "error": str(e),
                "timestamp": datetime.now().isoformat()
            }
    
    def _extract_resources(self, plan_data: Dict[str, Any]) -> List[Dict[str, Any]]:
        """Extract resource information from Terraform plan"""
        resources = []
        
        # Navigate through the plan structure
        planned_changes = plan_data.get("resource_changes", [])
        
        for change in planned_changes:
            resource_type = change.get("type", "")
            resource_name = change.get("name", "")
            change_actions = change.get("change", {}).get("actions", [])
            
            # Only include resources being created or modified
            if "create" in change_actions or "update" in change_actions:
                resources.append({
                    "type": resource_type,
                    "name": resource_name,
                    "actions": change_actions,
                    "address": change.get("address", "")
                })
        
        return resources
    
    def _estimate_resource_cost(self, resource: Dict[str, Any], region: str) -> Dict[str, Any]:
        """Estimate cost for a specific resource"""
        resource_type = resource["type"]
        resource_name = resource["name"]
        
        # Basic cost estimates (these would be replaced with actual AWS pricing API calls)
        cost_estimates = {
            "aws_instance": {
                "category": "compute",
                "monthly_cost": 50.0,  # Example: t3.medium
                "description": "EC2 instance cost estimate"
            },
            "aws_db_instance": {
                "category": "database",
                "monthly_cost": 200.0,  # Example: db.t3.micro
                "description": "RDS instance cost estimate"
            },
            "aws_s3_bucket": {
                "category": "storage",
                "monthly_cost": 5.0,  # Base S3 cost
                "description": "S3 bucket storage cost estimate"
            },
            "aws_lambda_function": {
                "category": "compute",
                "monthly_cost": 10.0,  # Base Lambda cost
                "description": "Lambda function cost estimate"
            },
            "aws_cloudfront_distribution": {
                "category": "network",
                "monthly_cost": 15.0,  # Base CloudFront cost
                "description": "CloudFront distribution cost estimate"
            }
        }
        
        # Find matching cost estimate
        for aws_type, estimate in cost_estimates.items():
            if aws_type in resource_type:
                return {
                    "resource_type": resource_type,
                    "resource_name": resource_name,
                    "category": estimate["category"],
                    "monthly_cost": estimate["monthly_cost"],
                    "description": estimate["description"],
                    "region": region
                }
        
        # Default estimate for unknown resource types
        return {
            "resource_type": resource_type,
            "resource_name": resource_name,
            "category": "other",
            "monthly_cost": 25.0,
            "description": "Generic resource cost estimate",
            "region": region
        } 
#!/usr/bin/env python3
"""Cost Agent for MCP System"""

import asyncio
import json
from pathlib import Path
from typing import Dict, List, Any, Optional
from datetime import datetime

from mcp_server_legacy import Agent

class CostAgent(Agent):
    """Agent specialized in cost analysis and optimization"""
    
    def __init__(self):
        super().__init__(
            agent_id="cost_agent",
            name="Cost Analysis Agent",
            system_prompt="""
            You are a cost analysis agent specializing in infrastructure cost optimization.
            
            Your primary goals:
            1. Analyze infrastructure costs from Terraform configurations
            2. Identify cost optimization opportunities
            3. Provide cost estimates and projections
            4. Recommend cost-saving strategies
            5. Track cost trends and patterns
            
            Your responsibilities:
            - Perform detailed cost analysis using pricing data
            - Identify over-provisioned or underutilized resources
            - Suggest cost optimization strategies
            - Generate cost reports and projections
            - Monitor cost trends over time
            
            Available tools: cost_analyzer, document_generator
            
            Always prioritize cost-effective solutions while maintaining performance and security.
            """,
            tools=["cost_analyzer", "document_generator"]
        )
    
    async def _execute_action_impl(self, action: str, parameters: Dict[str, Any]) -> Dict[str, Any]:
        """Implementation of cost agent actions"""
        
        if action == "analyze_costs":
            return await self._analyze_costs(parameters)
        elif action == "optimize_costs":
            return await self._optimize_costs(parameters)
        elif action == "generate_cost_report":
            return await self._generate_cost_report(parameters)
        elif action == "get_cost_status":
            return await self._get_cost_status(parameters)
        else:
            raise ValueError(f"Unknown action: {action}")
    
    async def _analyze_costs(self, parameters: Dict[str, Any]) -> Dict[str, Any]:
        """Perform comprehensive cost analysis"""
        try:
            plan_json = parameters["plan_json"]
            region = parameters.get("region", "us-east-1")
            include_estimate = parameters.get("include_estimate", True)
            output_path = parameters.get("output_path", f"output/cost_analysis_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json")
            
            # Step 1: Run cost analysis
            self.state.update_progress(0.3)
            cost_result = await self._invoke_tool("cost_analyzer", {
                "plan_json": plan_json,
                "region": region,
                "include_estimate": include_estimate
            })
            
            if cost_result.get("status") == "error":
                return {
                    "status": "error",
                    "message": f"Cost analysis failed: {cost_result.get('error')}",
                    "timestamp": datetime.now().isoformat()
                }
            
            # Step 2: Generate cost report
            self.state.update_progress(0.7)
            report_result = await self._invoke_tool("document_generator", {
                "analysis_file": output_path,
                "document_type": "executive_summary",
                "output_format": "html"
            })
            
            # Extract cost data
            cost_data = cost_result.get("result", {}).get("analysis", {})
            total_monthly_cost = cost_data.get("total_estimated_monthly_cost", 0.0)
            cost_breakdown = cost_data.get("cost_breakdown", {})
            
            # Store analysis in memory
            cost_summary = {
                "plan_json": plan_json,
                "region": region,
                "analysis_timestamp": datetime.now().isoformat(),
                "total_monthly_cost": total_monthly_cost,
                "cost_breakdown": cost_breakdown,
                "resource_costs": cost_data.get("resource_costs", []),
                "report_file": report_result.get("result", {}).get("document_file")
            }
            
            self.memory.store_long_term(f"cost_analysis_{datetime.now().strftime('%Y%m%d_%H%M%S')}", cost_summary)
            
            return {
                "status": "success",
                "message": "Cost analysis completed successfully",
                "total_monthly_cost": total_monthly_cost,
                "cost_breakdown": cost_breakdown,
                "resource_costs": cost_data.get("resource_costs", []),
                "report_file": report_result.get("result", {}).get("document_file"),
                "region": region,
                "timestamp": datetime.now().isoformat()
            }
            
        except Exception as e:
            return {
                "status": "error",
                "message": f"Cost analysis failed: {str(e)}",
                "timestamp": datetime.now().isoformat()
            }
    
    async def _optimize_costs(self, parameters: Dict[str, Any]) -> Dict[str, Any]:
        """Provide cost optimization recommendations"""
        try:
            plan_json = parameters["plan_json"]
            region = parameters.get("region", "us-east-1")
            
            # Run cost analysis first
            cost_result = await self._invoke_tool("cost_analyzer", {
                "plan_json": plan_json,
                "region": region,
                "include_estimate": True
            })
            
            if cost_result.get("status") == "error":
                return {
                    "status": "error",
                    "message": f"Cost optimization failed: {cost_result.get('error')}",
                    "timestamp": datetime.now().isoformat()
                }
            
            # Analyze cost data for optimization opportunities
            cost_data = cost_result.get("result", {}).get("analysis", {})
            resource_costs = cost_data.get("resource_costs", [])
            
            # Generate optimization recommendations
            optimization_recommendations = self._generate_optimization_recommendations(resource_costs, region)
            
            # Calculate potential savings
            potential_savings = self._calculate_potential_savings(optimization_recommendations)
            
            return {
                "status": "success",
                "message": "Cost optimization analysis completed",
                "current_monthly_cost": cost_data.get("total_estimated_monthly_cost", 0.0),
                "potential_monthly_savings": potential_savings,
                "savings_percentage": (potential_savings / cost_data.get("total_estimated_monthly_cost", 1.0)) * 100,
                "optimization_recommendations": optimization_recommendations,
                "region": region,
                "timestamp": datetime.now().isoformat()
            }
            
        except Exception as e:
            return {
                "status": "error",
                "message": f"Cost optimization failed: {str(e)}",
                "timestamp": datetime.now().isoformat()
            }
    
    async def _generate_cost_report(self, parameters: Dict[str, Any]) -> Dict[str, Any]:
        """Generate comprehensive cost report"""
        try:
            analysis_file = parameters["analysis_file"]
            
            result = await self._invoke_tool("document_generator", {
                "analysis_file": analysis_file,
                "document_type": "executive_summary",
                "output_format": "html",
                "include_charts": True
            })
            
            return {
                "status": "success",
                "message": "Cost report generated successfully",
                "report_file": result.get("result", {}).get("document_file"),
                "timestamp": datetime.now().isoformat()
            }
            
        except Exception as e:
            return {
                "status": "error",
                "message": f"Cost report generation failed: {str(e)}",
                "timestamp": datetime.now().isoformat()
            }
    
    async def _get_cost_status(self, parameters: Dict[str, Any]) -> Dict[str, Any]:
        """Get current cost status and trends"""
        try:
            # Retrieve recent cost analyses from memory
            recent_analyses = []
            for key, value in self.memory.long_term.items():
                if key.startswith("cost_analysis_"):
                    recent_analyses.append(value["value"])
            
            # Sort by timestamp
            recent_analyses.sort(key=lambda x: x.get("analysis_timestamp", ""), reverse=True)
            
            # Calculate cost metrics
            total_analyses = len(recent_analyses)
            total_monthly_cost = sum(analysis.get("total_monthly_cost", 0.0) for analysis in recent_analyses)
            avg_monthly_cost = total_monthly_cost / total_analyses if total_analyses > 0 else 0.0
            
            # Calculate trends
            recent_costs = [analysis.get("total_monthly_cost", 0.0) for analysis in recent_analyses[:5]]
            trend = "decreasing" if len(recent_costs) >= 2 and recent_costs[0] < recent_costs[-1] else "stable"
            
            # Get cost breakdown trends
            cost_breakdown_trends = self._analyze_cost_breakdown_trends(recent_analyses)
            
            return {
                "status": "success",
                "cost_status": {
                    "total_analyses": total_analyses,
                    "total_monthly_cost": round(total_monthly_cost, 2),
                    "average_monthly_cost": round(avg_monthly_cost, 2),
                    "trend": trend,
                    "cost_breakdown_trends": cost_breakdown_trends,
                    "last_analysis": recent_analyses[0] if recent_analyses else None,
                    "recent_analyses": recent_analyses[:5]
                },
                "timestamp": datetime.now().isoformat()
            }
            
        except Exception as e:
            return {
                "status": "error",
                "message": f"Failed to get cost status: {str(e)}",
                "timestamp": datetime.now().isoformat()
            }
    
    def _generate_optimization_recommendations(self, resource_costs: List[Dict[str, Any]], region: str) -> List[Dict[str, Any]]:
        """Generate cost optimization recommendations"""
        recommendations = []
        
        for resource_cost in resource_costs:
            resource_type = resource_cost.get("resource_type", "")
            monthly_cost = resource_cost.get("monthly_cost", 0.0)
            category = resource_cost.get("category", "")
            
            # Generate recommendations based on resource type and cost
            if "aws_instance" in resource_type and monthly_cost > 100:
                recommendations.append({
                    "resource_type": resource_type,
                    "resource_name": resource_cost.get("resource_name", ""),
                    "current_cost": monthly_cost,
                    "recommendation": "Consider using Spot Instances for non-critical workloads",
                    "potential_savings": monthly_cost * 0.6,  # 60% savings with Spot
                    "priority": "high" if monthly_cost > 200 else "medium"
                })
            
            elif "aws_db_instance" in resource_type and monthly_cost > 150:
                recommendations.append({
                    "resource_type": resource_type,
                    "resource_name": resource_cost.get("resource_name", ""),
                    "current_cost": monthly_cost,
                    "recommendation": "Review instance size and consider Reserved Instances",
                    "potential_savings": monthly_cost * 0.3,  # 30% savings with RI
                    "priority": "high"
                })
            
            elif "aws_s3_bucket" in resource_type and monthly_cost > 50:
                recommendations.append({
                    "resource_type": resource_type,
                    "resource_name": resource_cost.get("resource_name", ""),
                    "current_cost": monthly_cost,
                    "recommendation": "Implement lifecycle policies to move data to cheaper storage tiers",
                    "potential_savings": monthly_cost * 0.4,  # 40% savings with lifecycle policies
                    "priority": "medium"
                })
            
            elif category == "network" and monthly_cost > 100:
                recommendations.append({
                    "resource_type": resource_type,
                    "resource_name": resource_cost.get("resource_name", ""),
                    "current_cost": monthly_cost,
                    "recommendation": "Review network configuration and consider data transfer optimization",
                    "potential_savings": monthly_cost * 0.2,  # 20% savings
                    "priority": "medium"
                })
        
        return recommendations
    
    def _calculate_potential_savings(self, recommendations: List[Dict[str, Any]]) -> float:
        """Calculate total potential monthly savings"""
        total_savings = 0.0
        for rec in recommendations:
            total_savings += rec.get("potential_savings", 0.0)
        return total_savings
    
    def _analyze_cost_breakdown_trends(self, recent_analyses: List[Dict[str, Any]]) -> Dict[str, Any]:
        """Analyze cost breakdown trends over time"""
        if not recent_analyses:
            return {}
        
        # Get cost breakdowns from recent analyses
        breakdowns = [analysis.get("cost_breakdown", {}) for analysis in recent_analyses[:5]]
        
        # Calculate averages for each category
        categories = ["compute", "storage", "network", "database", "other"]
        trend_data = {}
        
        for category in categories:
            category_costs = [bd.get(category, 0.0) for bd in breakdowns if bd]
            if category_costs:
                avg_cost = sum(category_costs) / len(category_costs)
                trend_data[category] = {
                    "average_cost": round(avg_cost, 2),
                    "trend": "stable"  # Could be enhanced with actual trend calculation
                }
        
        return trend_data
    
    async def _invoke_tool(self, tool_id: str, parameters: Dict[str, Any]) -> Dict[str, Any]:
        """Invoke a tool and return the result"""
        from mcp_server_legacy import mcp_host
        tool = mcp_host.get_tool(tool_id)
        if not tool:
            return {
                "status": "error",
                "error": f"Tool '{tool_id}' not found",
                "timestamp": datetime.now().isoformat()
            }
        
        # Execute the tool's action
        return await tool.invoke(parameters) 
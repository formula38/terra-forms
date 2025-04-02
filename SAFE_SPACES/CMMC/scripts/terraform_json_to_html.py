import json
import sys
import datetime
import getpass

AWS_COST_ESTIMATES = {
    "aws_instance": 25.0,
    "aws_s3_bucket": 0.02,
    "aws_cloudfront_distribution": 2.5,
    "aws_iam_role": 0,
    "aws_kms_key": 1.0,
    "aws_db_instance": 20.0,
    "aws_subnet": 0,
    "aws_security_group": 0,
    "aws_vpc": 0,
    "aws_lambda_function": 1.5,
    "default": 0.5
}

def estimate_cost(resource_type):
    return AWS_COST_ESTIMATES.get(resource_type, AWS_COST_ESTIMATES["default"])

def infer_module(name):
    name = name.lower()
    if "vpc" in name or "subnet" in name or "route" in name:
        return "Networking"
    if "s3" in name or "bucket" in name:
        return "S3"
    if "iam" in name or "role" in name:
        return "IAM"
    if "log" in name or "cloudwatch" in name:
        return "Logging"
    if "kms" in name:
        return "Encryption"
    if "db" in name or "rds" in name:
        return "Database"
    if "acl" in name or "policy" in name:
        return "Access Control"
    if "cloudfront" in name or "cdn" in name:
        return "CDN"
    return "General"

def generate_html(plan_json):
    timestamp = datetime.datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S UTC")
    user = getpass.getuser()
    resource_changes = plan_json.get("resource_changes", [])

    grouped = {"create": {}, "update": {}, "delete": {}, "other": {}}
    total_cost = 0.0

    for change in resource_changes:
        actions = change.get("change", {}).get("actions", [])
        name = change.get("name", "")
        r_type = change.get("type", "")
        module = infer_module(name)
        action_type = next((a for a in ["create", "update", "delete"] if a in actions), "other")
        cost = estimate_cost(r_type)
        grouped[action_type].setdefault(module, []).append((change, cost))
        if "create" in actions:
            total_cost += cost

    html = f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Terraform Plan Summary</title>
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css">
<style>
body {{
    font-family: 'Segoe UI', sans-serif;
    background: #f4f6f9;
    color: #333;
    margin: 0;
    padding: 0;
}}
.sidebar {{
    width: 220px;
    background: #1a1a2e;
    color: white;
    height: 100vh;
    position: fixed;
    top: 0; left: 0;
    padding: 1em;
    overflow-y: auto;
}}
.sidebar h2 {{ font-size: 1.2em; margin-top: 0; }}
.sidebar ul {{ list-style: none; padding: 0; }}
.sidebar ul li {{
    padding: 8px 0;
    cursor: pointer;
    color: #ccc;
}}
.sidebar ul li:hover {{ color: white; }}
.main {{
    margin-left: 240px;
    padding: 2em;
}}
.meta, .controls {{ margin-bottom: 1em; }}
input, button {{
    padding: 8px;
    margin-right: 8px;
    border-radius: 4px;
    border: none;
}}
input {{ width: 250px; }}
button {{
    background-color: #1a1a2e;
    color: white;
    cursor: pointer;
}}
.tab {{ display: none; }}
.tab.active {{ display: block; }}
.tabs {{ margin-top: 2em; }}
.tab-buttons {{
    display: flex;
    gap: 10px;
    margin-bottom: 1em;
    flex-wrap: wrap;
}}
.tab-buttons button {{
    background: #1a1a2e;
    color: white;
    border: none;
    border-radius: 4px;
}}
.shared-table {{
    width: 100%;
    border-collapse: collapse;
    table-layout: fixed;
}}
.shared-table th, .shared-table td {{
    padding: 10px;
    text-align: left;
    border-bottom: 1px solid #ccc;
}}
.shared-table th {{ background: #eee; }}
.action-create {{ background: #d4edda; color: #155724; padding: 2px 6px; border-radius: 4px; }}
.action-update {{ background: #fff3cd; color: #856404; padding: 2px 6px; border-radius: 4px; }}
.action-delete {{ background: #f8d7da; color: #721c24; padding: 2px 6px; border-radius: 4px; }}
.btn-icon {{
    cursor: pointer;
    margin-left: 8px;
    color: #3498db;
}}
.modal-overlay {{
    display: none;
    position: fixed;
    top: 0; left: 0;
    width: 100%; height: 100%;
    background: rgba(0,0,0,0.6);
    z-index: 999;
}}
.modal {{
    display: none;
    position: fixed;
    top: 5%;
    left: 10%;
    width: 80%;
    height: 85%;
    background: white;
    color: black;
    padding: 20px;
    overflow: auto;
    z-index: 1000;
}}
.modal pre {{
    background: #f4f4f4;
    padding: 1em;
    overflow-x: auto;
    white-space: pre-wrap;
    word-break: break-word;
}}
</style>
<script>
function openModal(id) {{
    document.getElementById('modal-overlay').style.display = 'block';
    document.getElementById(id).style.display = 'block';
}}
function closeModal(id) {{
    document.getElementById('modal-overlay').style.display = 'none';
    document.getElementById(id).style.display = 'none';
}}
function copyToClipboard(id) {{
    const text = document.getElementById(id).textContent;
    navigator.clipboard.writeText(text);
    alert("Copied!");
}}
function toggleTab(id) {{
    document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
    document.getElementById(id).classList.add('active');
}}
function saveHTML() {{
    const blob = new Blob([document.documentElement.outerHTML], {{ type: 'text/html' }});
    const a = document.createElement('a');
    a.href = URL.createObjectURL(blob);
    a.download = "terraform_plan_summary.html";
    a.click();
}}
function searchResources() {{
    const q = document.getElementById("searchInput").value.toLowerCase();
    document.querySelectorAll(".tab").forEach(tab => {{
        let anyVisible = false;
        tab.querySelectorAll(".module-group").forEach(group => {{
            let groupVisible = false;
            group.querySelectorAll(".resource-row").forEach(row => {{
                const match = row.textContent.toLowerCase().includes(q);
                row.style.display = match ? "" : "none";
                if (match) groupVisible = true;
            }});
            group.style.display = groupVisible ? "" : "none";
            if (groupVisible) anyVisible = true;
        }});
        tab.style.display = anyVisible ? "block" : "none";
    }});
}}
</script>
</head>
<body>
<div class="sidebar">
    <h2>Navigation</h2>
    <ul>
        <li onclick="toggleTab('create')">➕ Create</li>
        <li onclick="toggleTab('update')">✏️ Update</li>
        <li onclick="toggleTab('delete')">🗑️ Delete</li>
        <li onclick="toggleTab('other')">❓ Other</li>
    </ul>
</div>
<div class="main">
<h1>Terraform Plan Summary</h1>
<div class="meta">
Generated by: <strong>{user}</strong><br>
Timestamp: <strong>{timestamp}</strong><br>
Total resources affected: <strong>{len(resource_changes)}</strong><br>
Estimated monthly AWS cost: <strong>${total_cost:.2f}</strong>
</div>
<div class="controls">
    <input type="text" id="searchInput" placeholder="Live search..." onkeyup="searchResources()">
    <button onclick="saveHTML()">💾 Save/Share HTML</button>
</div>
<div class="tabs">
"""

    for action in ["create", "update", "delete", "other"]:
        modules = grouped[action]
        html += f'<div class="tab" id="{action}"><div class="tab-buttons">'
        for module in modules:
            html += f'<button onclick="document.getElementById(\'{action}_{module}\').scrollIntoView();">{module}</button>'
        html += '</div>'
        for module, resources in modules.items():
            html += f'<div class="module-group" id="{action}_{module}"><h3>{module}</h3><table class="shared-table"><thead><tr><th>Type</th><th>Name</th><th>Action</th><th>Cost</th><th>Details</th></tr></thead><tbody>'
            for i, (res, cost) in enumerate(resources):
                rid = f"{action}_{module}_{i}"
                jstr = json.dumps(res, indent=2).replace("</script>", "<\\/script>")
                html += f"""<tr class="resource-row">
                    <td>{res.get("type")}</td>
                    <td>{res.get("name")}</td>
                    <td><span class="action-{action}">{action.upper()}</span></td>
                    <td>${cost:.2f}</td>
                    <td>
                        <span class="btn-icon" onclick="openModal('modal_{rid}')"><i class="fas fa-eye"></i></span>
                        <span class="btn-icon" onclick="copyToClipboard('json_{rid}')"><i class="fas fa-copy"></i></span>
                    </td>
                </tr>
                <div class="modal" id="modal_{rid}">
                    <button onclick="closeModal('modal_{rid}')">Close</button>
                    <pre id="json_{rid}">{jstr}</pre>
                </div>"""
            html += "</tbody></table></div>"
        html += "</div>"

    html += """</div></div><div id="modal-overlay" class="modal-overlay"></div></body></html>"""
    return html

if __name__ == "__main__":
    tf_json_path = sys.argv[1]
    html_output_path = sys.argv[2]
    with open(tf_json_path, "r") as f:
        tf_data = json.load(f)
    html = generate_html(tf_data)
    with open(html_output_path, "w") as f:
        f.write(html)

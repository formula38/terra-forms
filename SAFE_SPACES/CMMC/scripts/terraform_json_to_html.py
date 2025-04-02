import json
import sys

def generate_html(plan_json):
    html = """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Terraform Plan Summary</title>
    <style>
        body { font-family: Arial, sans-serif; padding: 2em; background: #f9f9f9; }
        h1 { color: #333; }
        table { width: 100%; border-collapse: collapse; margin-top: 1em; }
        th, td { padding: 10px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background-color: #4CAF50; color: white; }
        .action-create { background-color: #d4edda; color: #155724; font-weight: bold; padding: 4px 8px; border-radius: 4px; }
        .action-update { background-color: #fff3cd; color: #856404; font-weight: bold; padding: 4px 8px; border-radius: 4px; }
        .action-delete { background-color: #f8d7da; color: #721c24; font-weight: bold; padding: 4px 8px; border-radius: 4px; }
    </style>
</head>
<body>
    <h1>Terraform Plan Summary</h1>
    <table>
        <thead>
            <tr>
                <th>Resource Type</th>
                <th>Resource Name</th>
                <th>Action</th>
            </tr>
        </thead>
        <tbody>
    """

    count = 0
    for change in plan_json.get("resource_changes", []):
        resource_type = change.get("type")
        resource_name = change.get("name")
        actions = change.get("change", {}).get("actions", [])
        action_class = "action-" + ("create" if "create" in actions else "update" if "update" in actions else "delete")
        action_text = ", ".join(actions)
        count += 1

        html += f"""
        <tr>
            <td>{resource_type}</td>
            <td><strong>{resource_name}</strong></td>
            <td><span class="{action_class}">{action_text}</span></td>
        </tr>
        """

    html += f"""
        </tbody>
    </table>
    <p><strong>Total resources affected:</strong> {count}</p>
</body>
</html>
"""
    return html

if __name__ == "__main__":
    tf_json_path = sys.argv[1]
    html_output_path = sys.argv[2]

    with open(tf_json_path, "r") as f:
        tf_data = json.load(f)

    html = generate_html(tf_data)

    with open(html_output_path, "w") as f:
        f.write(html)

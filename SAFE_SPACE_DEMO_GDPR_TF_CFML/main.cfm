<!---ColdFusion on the EC2 Instance: Once the EC2 instance is deployed, ColdFusion (running
within the instance) will handle the ITaaS portions, such as running additional Terraform
commands, managing configurations, and interacting with the AWS infrastructure.--->






<cfscript>
// Define the paths to your Terraform files
    terraformDirectory = "/var/www/html/terraform"; // Assume Terraform files are in this directory
    terraformExecutable = "/usr/bin/terraform";

// Initialize Terraform
    initCommand = terraformExecutable & " init";
    result = cfexecute(name="bash", arguments="-c " & initCommand, timeout="600", variable="initOutput");
    writeOutput("<h3>Terraform Initialization:</h3>");
    writeOutput("<pre>" & initOutput & "</pre>");

// Apply additional Terraform configuration if needed
    applyCommand = terraformExecutable & " apply -auto-approve";
    result = cfexecute(name="bash", arguments="-c " & applyCommand, timeout="1200", variable="applyOutput");
    writeOutput("<h3>Terraform Apply:</h3>");
    writeOutput("<pre>" & applyOutput & "</pre>");

// Output or analyze specific Terraform outputs
    outputCommand = terraformExecutable & " output -json";
    result = cfexecute(name="bash", arguments="-c " & outputCommand, timeout="600", variable="outputJson");
    terraformOutputs = deserializeJSON(outputJson);
    writeOutput("<h3>Terraform Outputs:</h3>");
    writeOutput("<pre>" & serializeJSON(terraformOutputs, true) & "</pre>");

// Analyze logs or outputs for GDPR compliance
    s3Encryption = terraformOutputs["mybucket_encryption"]["value"];
    if (s3Encryption eq "enabled") {
        writeOutput("<p>S3 Bucket is encrypted: Compliant</p>");
    } else {
        writeOutput("<p>S3 Bucket is not encrypted: Non-compliant</p>");
    }
</cfscript>

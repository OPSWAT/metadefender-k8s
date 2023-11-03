## Generating a support package

In case of issues that require further investigation by OPSWAT support, a package can be generated using the `sp.sh` script what contains pod logs, configurations and details regarding the Kubernetes deployment. In order to generate the support package, make the `sp.sh` script executable and run the following command:
```
./sp.sh <NAMESPACE>
```
Notes:
- The namespace name where the application is deployed needs to be specified as an argument, otherwise the default namespace is used.
- The script uses `kubectl` to extract the required information, make sure `kubectl` is installed and configured with the correct context.
- The script generates the support package as a zip file in the same directory where it is executed.
# Overview

This is a program to supplement read-only access that is not covered by the AWS managed policy "ReadOnlyAccess".

If you use it as is, a file called ComplementReadOnlyAccess.json will be generated, so you can use it together with ReadOnlyAccess to supplement the read-only actions of actions that are not covered.

For example, as of December 26th, 2024, ReadOnlyAccess does not include read-only actions for AWS services such as AWS Control Tower and Redshift Serverless.

# Prerequisites

## Usage

### Common Processing

1. In your terminal, change to a local directory

2. Clone the repository

   ```bash
   git clone https://github.com/kazzpapa3/CreateComplementReadOnlyAccess.git
   ```

#### Execution in a shell script

1. If you have just cloned from GitHub, "CreateComplementReadOnlyAccess" will be created directly under it, so change directory.

   ```bash
   cd CreateComplementReadOnlyAccess
   ```

2. In the exec.sh file located directly under the CreateComplementReadOnlyAccess directory, enter the option "-e".
   e.g.)

   ```bash
   ./exec.sh -e
   ```

3. After execution, a ComplementReadOnlyAccess.json file will be generated in the local directory.  
   You can use this file as a basis to create a custom managed policy and use it in conjunction with the AWS managed policy ReadOnlyAccess.

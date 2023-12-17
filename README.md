# Command Central (Under Development - 1 Function Released)

## Introduction

Command Central is a powerful GUI tool under construction that is designed for Helpdesk and Desktop Support Technicians (for advanced proffesionals too!). It simplifies common tasks and automates various processes, making it an invaluable resource for both beginners and advanced professionals in the IT field.

## Features

- **Uninstallation Automation:** Command Central can help you identify and uninstall unwanted software from your system, streamlining the cleanup process.

- **App Approval System:** The script includes an app approval system that ensures critical applications remain untouched, reducing the risk of accidental removal.

- **Uninstall Options Database:** Command Central maintains a database of uninstallation options for different applications, providing more control over the process.

- **Silent Uninstallations:** The tool supports silent uninstallations using common switches for MSI-installed and other types of applications.

## Usage

### Prerequisites

Before using Command Central, ensure that you have the following prerequisites in place:

- PowerShell 5.1 or higher
- Administrator privileges (required for uninstallations)

### Installation

1. Clone or download the Command Central repository from GitHub.
2. Navigate to the project directory.

### Running Command Central

To run Command Central:

1. Open a PowerShell window with administrative privileges.
2. Navigate to the Command Central directory.
3. Execute the script by running the `UninstallUnapprovedAppsV0.01.ps1` file.

### Configuration

- Customize the list of pre-approved apps in the `Start_Variables` function.
- Maintain your uninstall options database by modifying the `uninstallOptionsDB.csv` file.

## Known Issues

- No known issues at the moment. Please report any problems in the [Issues](https://github.com/MissionControlFreak/Command Central/issues) section.

## Contributing

If you'd like to contribute to Command Central, please follow our [Contributing Guidelines](CONTRIBUTING.md).

## License

This project is licensed under the GNU GENERAL PUBLIC License v3.0 - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

Command Central was developed with the support of the open-source community and various libraries and resources.

## Contact

---

Enjoy using Command Central and simplify your IT support tasks!

# Command Central
CommandCentral is a versatile PowerShell tool designed to streamline various administrative tasks with menu-driven navigation and built-in credential stores. This README provides an overview of the tool's functionality and how to use it effectively.

## <------------------------------------------------- Table of Contents ------------------------------------------------->
**IN PROGRESS, READ ON**
## <-------------------------------------------------  End of Contents  ------------------------------------------------->

**Features:**
1. **Menu-Driven Navigation:** CommandCentral provides a user-friendly menu interface for navigating through PowerShell scripts and directories. Users can easily select scripts to run, explore subdirectories, or navigate back to previous directories. This intuitive interface enhances usability and efficiency when managing multiple scripts and directories.
2. **Script Updates:** The tool includes functionality to check for updates to the main script stored on a GitHub repository. It compares the local script with the version on GitHub and automatically updates if discrepancies are found. This ensures users always have access to the latest version of the tool.
3. **Credential Management:** CommandCentral simplifies the process of managing user credentials, particularly in domain environments. It automatically detects whether the computer is part of a domain and prompts users to provide their credentials if necessary. It also supports storing and retrieving credentials securely using PowerShell's Credential Manager.

**Usage:**
1. **Getting Started:** Clone or download the CommandCentral repository from GitHub to your local machine and extract if neccesary (It is preferable to save it to "C:\Users\%USERNAME%\Appdata\Roaming" for cleanliness and has the added benefit of being able to roam with the script accross multiple computers in a domain if your profile is configured to do so.
3. **Running the Script:** Create a shortcut of the `CommandCentral.ps1` on your desktop, right click on it, then hit "Run with powershell" or open PowerShell and navigate to the directory where CommandCentral is stored. Run the `CommandCentral.ps1` script to launch the tool.
4. **Credential Management:** If the computer is part of a domain, CommandCentral will prompt you to provide your credentials. These credentials are securely stored via Microsoft's DPAPI algorithm and can be retrieved automatically for subsequent use.
5. **Checking for Updates:** CommandCentral automatically checks for updates to the main script on GitHub. If updates are available, it will prompt you to update the local script to the latest version.
6. **Navigating Menus:** Use the displayed menu options to navigate through scripts and directories. Select the desired option by entering the corresponding number or quit the tool by entering 'q' or 'quit'.

**Contributing:**
Contributions to CommandCentral are welcome! If you encounter any issues, have suggestions for improvements, or would like to contribute new features, please open an issue or submit a pull request on GitHub.
**License:**
This project is licensed under the GNU GENERAL PUBLIC License v3.0 - see the [LICENSE](LICENSE) file for details.

**Acknowledgments:**
CommandCentral was developed by [Admiral-AI](https://github.com/Admiral-AI) to simplify administrative tasks and enhance PowerShell scripting capabilities. I extend my gratitude to the entire PowerShell community for their support and contributions.

**Contact:**
For questions, feedback, or support inquiries, please contact [Admiral-AI](https://github.com/Admiral-AI) via GitHub.
Thank you for using CommandCentral! We hope it helps streamline your administrative tasks and improves your PowerShell scripting experience.


## <------------------------------------------------- Old Menu  ------------------------------------------------->
# Command Central (Under Development - 1 Function Released, 1 Under Construction)

## Introduction

Command Central is a powerful GUI tool under construction that is designed for Helpdesk and Desktop Support Technicians (for advanced profesionals too!). It simplifies common tasks and automates various processes, making it an invaluable resource for both beginners and advanced professionals in the IT field.

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

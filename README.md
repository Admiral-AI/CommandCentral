# CommandCentral
CommandCentral is a versatile PowerShell tool designed to streamline various administrative tasks with menu-driven navigation and built-in credential stores. This README provides an overview of the tool's functionality and how to use it effectively.

## <------ Table of Contents ------>
**IN PROGRESS, READ ON**
## <------  End of Contents  ------>

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

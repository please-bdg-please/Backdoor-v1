// Proprietary Software License Version 1.0
//
// Copyright (C) 2025 BDG
//
// Backdoor App Signer is proprietary software. You may not use, modify, or distribute it except as expressly permitted under the terms of the Proprietary Software License.

import UIKit

/// View controller for managing AI learning settings
class AILearningSettingsViewController: UITableViewController {
    
    // MARK: - Properties
    
    private let cellReuseIdentifier = "AILearningSettingCell"
    private let switchCellReuseIdentifier = "AILearningSwitchCell"
    
    // Activity indicator for training
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    
    // Section indices
    private enum Section: Int {
        case about = 0
        case settings = 1
        case status = 2
        case actions = 3
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "AI Learning"
        
        // Configure table view
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellReuseIdentifier)
        tableView.register(SwitchTableViewCell.self, forCellReuseIdentifier: switchCellReuseIdentifier)
        tableView.tableFooterView = UIView()
        
        // Add observer for model updates
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(modelUpdated),
            name: Notification.Name("AIModelUpdated"),
            object: nil
        )
        
        // Set up activity indicator in navigation bar
        activityIndicator.hidesWhenStopped = true
        let barButton = UIBarButtonItem(customView: activityIndicator)
        navigationItem.rightBarButtonItem = barButton
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
    
    @objc private func modelUpdated() {
        DispatchQueue.main.async {
            self.activityIndicator.stopAnimating()
            self.tableView.reloadSections(IndexSet(integer: Section.status.rawValue), with: .automatic)
            
            // Show a notification
            let alert = UIAlertController(
                title: "AI Model Updated",
                message: "The AI has been updated with your feedback on previous interactions.",
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            
            self.present(alert, animated: true)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Table View Data Source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section) {
        case .about:
            return 1
        case .settings:
            return 1
        case .status:
            return 3
        case .actions:
            return 2
        case .none:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch Section(rawValue: indexPath.section) {
        case .about:
            let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier, for: indexPath)
            cell.textLabel?.text = "The AI assistant can learn from your feedback and improve over time."
            cell.textLabel?.numberOfLines = 0
            cell.accessoryType = .none
            cell.selectionStyle = .none
            return cell
            
        case .settings:
            let cell = tableView.dequeueReusableCell(withIdentifier: switchCellReuseIdentifier, for: indexPath) as! SwitchTableViewCell
            cell.textLabel?.text = "Enable AI Learning"
            cell.switchControl.isOn = AILearningManager.shared.isLearningEnabled
            cell.switchValueChanged = { isOn in
                AILearningManager.shared.setLearningEnabled(isOn)
                self.tableView.reloadSections(IndexSet(integer: Section.actions.rawValue), with: .automatic)
            }
            return cell
            
        case .status:
            let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier, for: indexPath)
            cell.selectionStyle = .none
            
            let stats = AILearningManager.shared.getLearningStatistics()
            
            if indexPath.row == 0 {
                cell.textLabel?.text = "Current model version: \(stats.modelVersion)"
            } else if indexPath.row == 1 {
                cell.textLabel?.text = "Stored interactions: \(stats.totalInteractions)"
            } else {
                cell.textLabel?.text = "Average feedback rating: \(String(format: "%.1f", stats.averageFeedbackRating))"
            }
            
            return cell
            
        case .actions:
            let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier, for: indexPath)
            
            if indexPath.row == 0 {
                cell.textLabel?.text = "Train Model Now"
                cell.accessoryType = .disclosureIndicator
                cell.selectionStyle = .default
                // Disable if learning is disabled
                cell.isUserInteractionEnabled = AILearningManager.shared.isLearningEnabled
                cell.textLabel?.isEnabled = AILearningManager.shared.isLearningEnabled
            } else {
                cell.textLabel?.text = "Clear Stored Interactions"
                cell.accessoryType = .disclosureIndicator
                cell.selectionStyle = .default
            }
            
            return cell
            
        case .none:
            return UITableViewCell()
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Section(rawValue: section) {
        case .about:
            return "About AI Learning"
        case .settings:
            return "Settings"
        case .status:
            return "Status"
        case .actions:
            return "Actions"
        case .none:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == Section.actions.rawValue {
            if indexPath.row == 0 {
                trainModelNow()
            } else {
                promptClearInteractions()
            }
        }
    }
    
    // MARK: - Actions
    
    private func trainModelNow() {
        // Show activity indicator
        activityIndicator.startAnimating()
        
        // Request model training
        AILearningManager.shared.trainModelNow { success, message in
            self.activityIndicator.stopAnimating()
            
            // Show result
            let title = success ? "Training Successful" : "Training Failed"
            let alert = UIAlertController(
                title: title,
                message: message,
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                // Reload status section
                self.tableView.reloadSections(IndexSet(integer: Section.status.rawValue), with: .automatic)
            })
            
            self.present(alert, animated: true)
        }
    }
    
    private func promptClearInteractions() {
        let alert = UIAlertController(
            title: "Clear Stored Interactions",
            message: "This will delete all stored AI interactions and feedback. This action cannot be undone.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        alert.addAction(UIAlertAction(title: "Clear", style: .destructive) { _ in
            // Clear interactions
            AILearningManager.shared.clearAllInteractions()
            
            // Reload status section
            self.tableView.reloadSections(IndexSet(integer: Section.status.rawValue), with: .automatic)
            
            // Show confirmation
            let confirmation = UIAlertController(
                title: "Interactions Cleared",
                message: "All stored AI interactions have been deleted.",
                preferredStyle: .alert
            )
            
            confirmation.addAction(UIAlertAction(title: "OK", style: .default))
            
            self.present(confirmation, animated: true)
        })
        
        present(alert, animated: true)
    }
}

// MARK: - Switch Cell

class SwitchTableViewCell: UITableViewCell {
    
    let switchControl = UISwitch()
    var switchValueChanged: ((Bool) -> Void)?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        switchControl.addTarget(self, action: #selector(switchChanged), for: .valueChanged)
        accessoryView = switchControl
        selectionStyle = .none
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func switchChanged() {
        switchValueChanged?(switchControl.isOn)
    }
}

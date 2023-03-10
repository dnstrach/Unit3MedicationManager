//
//  MedicationListViewController.swift
//  MedicationManager
//
//  Created by Dominique Strachan on 1/3/23.
//

import UIKit

class MedicationListViewController: UIViewController {
    

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var moodSurveyButton: UIButton!
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        MedicationController.shared.fetchMedications()
        
        //once adding observer need to remove addObserver when view controller is gone or else will cause memory leak
        //done through deinit above 
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(reminderFired),
                                               name: NSNotification.Name(Strings.medicationReminderReceived),
                                               object: nil)
        
        guard let survey = MoodSurveyController.shared.fetchTodaysSurveys() else { return }
        
        moodSurveyButton.setTitle(survey.mentalState, for: .normal)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tableView.reloadData()
    }
    
    //MARK: - Actions
    @IBAction func surveyButtonTapped(_ sender: Any) {
        guard let moodSurveyViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: Strings.moodSurveyViewController) as? MoodSurveyViewController else { return }
        
        moodSurveyViewController.delegate = self
        navigationController?.present(moodSurveyViewController, animated: true, completion: nil)
    }
    
    @objc private func reminderFired() {
        //print("\(#file) received the MEMO!")
        tableView.backgroundColor = .systemPurple
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.tableView.backgroundColor = .systemBackground
        }
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Strings.medicationDetailsSegueIdentifier,
           let indexPath = tableView.indexPathForSelectedRow,
           let destination = segue.destination as? MedicationDetailViewController {
            let medication = MedicationController.shared.sections[indexPath.section][indexPath.row]
            destination.medication = medication
            
        }
    }

}

extension MedicationListViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return MedicationController.shared.sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return MedicationController.shared.sections[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "medicationCell", for: indexPath) as? MedicationTableViewCell else { return UITableViewCell() }
        
        //medication is in sections array at specific section and its row containing cell
        let medication = MedicationController.shared.sections[indexPath.section][indexPath.row]
        
        cell.configure(with: medication)
//        cell.nameLabel.text = medication.name
//        cell.timeLabel.text = "\(medication.timeOfDay)"
        
        //assigning cell to be delegate for MedicationTableViewCellDelegate
        cell.delegate = self
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Not Taken"
        } else if section == 1 {
            return "Taken"
        } else {
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let medication = MedicationController.shared.sections[indexPath.section][indexPath.row]
            MedicationController.shared.deleteMedication(medication)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }
    
    
}

extension MedicationListViewController: UITableViewDelegate {
    
}

extension MedicationListViewController: MedicationTableViewCellDelegate {
    
    func medicationWasTakenButtonTapped(medication: Medication, wasTaken: Bool) {
        //delegate is sending info over to checkMedicationTaken func in MedicationController
        MedicationController.shared.markMedicationTaken(medication: medication, wasTaken: wasTaken)
        //shows check after clicking box
        tableView.reloadData()
    }
}

extension MedicationListViewController: MoodSurveyViewControllerDelegate {
    func moodButtonTapped(with emoji: String) {
        MoodSurveyController.shared.didTapMoodEmoji(emoji)
        moodSurveyButton.setTitle(emoji, for: .normal)
        
    }
}

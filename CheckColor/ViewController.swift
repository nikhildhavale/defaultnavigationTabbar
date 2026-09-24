//
//  ViewController.swift
//  CheckColor
//
//  Created by Nikhil Dhavale on 24/09/26.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        navigationItem.backButtonDisplayMode = .minimal

        let button = UIButton(type: .system)
        button.setTitle("Push Detail", for: .normal)
        button.addTarget(self, action: #selector(pushDetail), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(button)
        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            button.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        self.navigationItem.backButtonDisplayMode = .minimal
    }

    @objc private func pushDetail() {
        navigationController?.pushViewController(DetailViewController(), animated: true)
    }
}

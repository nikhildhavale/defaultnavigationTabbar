//
//  DetailViewController.swift
//  CheckColor
//

import UIKit

class DetailViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Detail"
        navigationItem.backButtonDisplayMode = .minimal
        // `.inline` still renders a LARGE title (and reverts to `.always` when a
        // back button is present). `.never` is what gives a small, centred title.
        navigationItem.largeTitleDisplayMode = .never
    }
}

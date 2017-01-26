//
//  FolderViewController.swift
//  DemoTar
//
//  Created by Konstantin Bukreev on 24.01.17.
//  Copyright © 2017 Konstantin Bukreev. All rights reserved.
//

import UIKit
import TarballKit

final class FolderViewController: UIViewController {

    let tableView = UITableView(frame: .zero, style: .plain)
    let folderPath: String
    var files: [String]

    init(folderPath: String) {

        self.folderPath = folderPath
        self.files = FolderViewController.loadItems(at: folderPath)
        super.init(nibName: nil, bundle: nil)
        self.title = "TARBALL DEMO"
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        tableView.frame = view.bounds
        tableView.autoresizingMask = [ .flexibleWidth, .flexibleHeight ]
        tableView.delegate = self
        tableView.dataSource = self
        view.addSubview(tableView)

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(actionAdd))
    }

    @objc private func actionAdd() {

        let alert = UIAlertController(title: "Add archive", message: nil, preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "File name" }
        alert.addTextField { $0.placeholder = "Content" }

        alert.addAction(UIAlertAction(title: "Add", style: .default, handler: { [weak alert, weak self] _ in
            guard let name = alert?.textFields?[0].text?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty else { return }
            let content = alert?.textFields?[1].text
            self?.addArchive(name: name, content: content)
            self?.reloadItems()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        present(alert, animated: true, completion: nil)
    }

    private func addArchive(name: String, content: String?) {

        let data = content?.data(using: .utf8) ?? Data()
        let filePath = folderPath + "/" + name + ".tar"

        do {
            let writer = try TarballWriter(filePath: filePath)
            try writer.write(data: data, path: "demo.txt")
        } catch {
            print("\(error)")
        }
    }

    private func reloadItems() {
        files = FolderViewController.loadItems(at: folderPath)
        tableView.reloadData()
    }

    static func loadItems(at folderPath: String) -> [String] {

        if let contens = try? FileManager.default.contentsOfDirectory(atPath: folderPath) {
            return contens.flatMap{ fileName in
                if fileName.hasSuffix(".tar") || fileName.hasSuffix(".tgz") || fileName.hasSuffix(".tar.gz") || fileName.hasSuffix(".tar.bz2") || fileName.hasSuffix(".tbz") {
                    return folderPath + "/" + fileName
                }
                return nil
            }
        } else {
            return []
        }
    }
}

extension FolderViewController: UITableViewDataSource {

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return files.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") ?? UITableViewCell(style: .default, reuseIdentifier: "Cell")
        cell.textLabel?.text = (files[indexPath.row] as NSString).lastPathComponent;
        return cell
    }
}

extension FolderViewController: UITableViewDelegate {

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        tableView.deselectRow(at: indexPath, animated: true)
        let file = files[indexPath.row]
        if let vc = TarballViewController(filePath: file) {
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}


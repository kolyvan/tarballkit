//
//  TarballViewController.swift
//  TarballKit
//
//  Created by Konstantin Bukreev on 24.01.17.
//  Copyright © 2017 Konstantin Bukreev. All rights reserved.
//

import UIKit
import TarballKit
import QuickLook

final class TarballViewController: UIViewController {

    let tableView = UITableView(frame: .zero, style: .plain)
    let filePath: String
    var items: [TarballItem]
    fileprivate var quickLookItem: URL? = nil

    init?(filePath: String) {

        let reader = TarballReader(filePath: filePath)
        self.items = (try? reader.items()) ?? []
        self.filePath = filePath
        super.init(nibName: nil, bundle: nil)
        self.title = (reader.filePath as NSString).lastPathComponent
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }

    deinit {
        if let url = quickLookItem {
            try? FileManager.default.removeItem(at: url)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        tableView.frame = view.bounds
        tableView.autoresizingMask = [ .flexibleWidth, .flexibleHeight ]
        tableView.delegate = self
        tableView.dataSource = self
        view.addSubview(tableView)

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(actionWrite))
    }

    fileprivate func show(item: TarballItem) throws {

        let reader = TarballReader(filePath: filePath)

        let data = try reader.read(item: item)

        let tmpPath = NSTemporaryDirectory() + "/" + item.path
        let url = URL(fileURLWithPath: tmpPath)
        let folderUrl = url.deletingLastPathComponent()
        if !FileManager.default.fileExists(atPath: folderUrl.path) {
            try FileManager.default.createDirectory(at: folderUrl, withIntermediateDirectories: true, attributes: [:])
        }

        try data.write(to: url)

        quickLookItem = url
        let vc = QLPreviewController()
        vc.delegate = self
        vc.dataSource = self
        present(vc, animated: true, completion: nil)
    }

    @objc private func actionWrite() {

        let alert = UIAlertController(title: "Write entry", message: nil, preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Entry name" }
        alert.addTextField { $0.placeholder = "Content" }

        alert.addAction(UIAlertAction(title: "Write", style: .default, handler: { [weak alert, weak self] _ in
            guard let name = alert?.textFields?[0].text?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty else { return }
            let content = alert?.textFields?[1].text
            self?.writeEntry(name: name, content: content)
            self?.reloadItems()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        present(alert, animated: true, completion: nil)
    }

    private func writeEntry(name: String, content: String?) {

        let data = content?.data(using: .utf8) ?? Data()

        do {
            let writer = try TarballWriter(filePath: filePath, append: true)
            try writer.write(data: data, path: name + ".txt")
        } catch {
            print("\(error)")
        }
    }

    private func reloadItems() {
        let reader = TarballReader(filePath: filePath)
        self.items = (try? reader.items()) ?? []
        tableView.reloadData()
    }
}

extension TarballViewController: UITableViewDataSource {

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = items[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") ?? UITableViewCell(style: .subtitle, reuseIdentifier: "Cell")
        cell.textLabel?.text = item.path
        cell.detailTextLabel?.text = "\(item.size) bytes"
        return cell
    }
}

extension TarballViewController: UITableViewDelegate {

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = items[indexPath.row]
        do {
            try show(item: item)
        } catch {
            print(String(reflecting: error))
        }
    }
}

extension TarballViewController: QLPreviewControllerDelegate {

    func previewControllerDidDismiss(_ controller: QLPreviewController) {

        if let url = quickLookItem {
            try? FileManager.default.removeItem(at: url)
            quickLookItem = nil
        }
        controller.delegate = nil
        controller.dataSource = nil
    }
}

extension TarballViewController: QLPreviewControllerDataSource {

    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }

    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return quickLookItem as! QLPreviewItem
    }
}

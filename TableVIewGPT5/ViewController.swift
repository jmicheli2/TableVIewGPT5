// Best @Mon Dec 9 18:11

// Still buggy - tried textview constraints top & bottom to 0



import UIKit

// MARK: - LargeTextViewCell
class LargeTextViewCell: UITableViewCell, UITextViewDelegate {
    let textView = UITextView()
    var textChangedHandler: ((String) -> Void)?
    var caretPositionHandler: ((CGRect) -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupTextView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupTextView() {
        textView.delegate = self
        textView.isScrollEnabled = false
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.layer.borderColor = UIColor.lightGray.cgColor
        textView.layer.borderWidth = 1.0
        textView.layer.cornerRadius = 8.0

        contentView.addSubview(textView)

        NSLayoutConstraint.activate([
            textView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 0), /*10*/
            textView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            textView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            textView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -0) /* -10 */
        ])
    }

    func configure(with text: String) {
        textView.text = text
    }

    // MARK: - UITextViewDelegate
    func textViewDidChange(_ textView: UITextView) {
        textChangedHandler?(textView.text)
    }

    func textViewDidChangeSelection(_ textView: UITextView) {
        let caretFrame = textView.caretRect(for: textView.selectedTextRange?.start ?? UITextPosition())
        caretPositionHandler?(caretFrame)
    }
}

// MARK: - ViewController
class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    private let tableView = UITableView()
    private var items = [String](repeating: "Edit me!", count: 5) // Sample data
    private var keyboardHeight: CGFloat = 0.0

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        registerKeyboardNotifications()
    }

    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(LargeTextViewCell.self, forCellReuseIdentifier: "LargeTextViewCell")
        tableView.estimatedRowHeight = 100 // Initial estimate for cell height
        tableView.rowHeight = UITableView.automaticDimension
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func registerKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc private func keyboardWillShow(notification: Notification) {
        if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            keyboardHeight = keyboardFrame.height
            adjustTableViewForKeyboard()
        }
    }

    @objc private func keyboardWillHide(notification: Notification) {
        keyboardHeight = 0
        adjustTableViewForKeyboard()
    }

    private func adjustTableViewForKeyboard() {
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardHeight, right: 0)
        tableView.scrollIndicatorInsets = tableView.contentInset
    }

    private func scrollToVisibleCell(at indexPath: IndexPath, caretFrame: CGRect) {
        guard let cell = tableView.cellForRow(at: indexPath) as? LargeTextViewCell else { return }
        let caretOnScreenFrame = cell.convert(caretFrame, to: tableView)

        if keyboardHeight > 0 && caretOnScreenFrame.maxY > tableView.bounds.height - keyboardHeight {
            tableView.scrollRectToVisible(caretOnScreenFrame, animated: true)
        }
    }

    // MARK: - UITableViewDataSource Methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "LargeTextViewCell", for: indexPath) as? LargeTextViewCell else {
            return UITableViewCell()
        }

        let text = items[indexPath.row]
        cell.configure(with: text)

        cell.textChangedHandler = { [weak self] updatedText in
            self?.items[indexPath.row] = updatedText

            UIView.performWithoutAnimation {
                self?.tableView.beginUpdates()
                self?.tableView.endUpdates()
            }

            // Scroll immediately after content update
            if let caretFrame = cell.textView.selectedTextRange?.start {
                let caretRect = cell.textView.caretRect(for: caretFrame)
                self?.scrollToVisibleCell(at: indexPath, caretFrame: caretRect)
            }
        }

        cell.caretPositionHandler = { [weak self] caretFrame in
            self?.scrollToVisibleCell(at: indexPath, caretFrame: caretFrame)
        }

        return cell
    }
}


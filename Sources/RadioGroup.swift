//
//  RadioGroup.swift
//  RadioGroup
//
//  Created by Yonat Sharon on 03.02.2019.
//

import UIKit

@IBDesignable open class RadioGroup: UIControl {
    public convenience init(titles: [String]) {
        self.init(frame: .zero)
        self.titles = titles
    }

    open var titles: [String?] {
        get {
            return items.map { $0.titleLabel.text }
        }
        set {
            stackView.removeAllArrangedSubviewsCompletely()
            stackView.addArrangedSubviews(newValue.map { RadioGroupItem(title: $0, group: self) })
            updateAllItems()
        }
    }

    open var attributedTitles: [NSAttributedString?] {
        get {
            return items.map { $0.titleLabel.attributedText }
        }
        set {
            stackView.removeAllArrangedSubviewsCompletely()
            stackView.addArrangedSubviews(newValue.map { RadioGroupItem(attributedTitle: $0, group: self) })
            updateAllItems()
        }
    }

    @IBInspectable open var selectedIndex: Int = -1 {
        didSet {
            item(at: oldValue)?.radioButton.isSelected = false
            item(at: selectedIndex)?.radioButton.isSelected = true
        }
    }

    /// Color of the inner circle of the selected radio button (nil = same as `tintColor`)
    @IBInspectable open dynamic var selectedColor: UIColor? {
        didSet {
            forEachItem { $0.radioButton.selectedColor = selectedColor }
        }
    }

    /// Color of the outer ring of the selected radio button (nil = same as `tintColor`)
    @IBInspectable open dynamic var selectedTintColor: UIColor? {
        didSet {
            forEachItem { $0.radioButton.selectedTintColor = selectedTintColor }
        }
    }

    @IBInspectable open dynamic var isVertical: Bool = true {
        didSet {
            stackView.axis = isVertical ? .vertical : .horizontal
        }
    }

    @IBInspectable open dynamic var buttonSize: CGFloat = 20 {
        didSet {
            forEachItem { $0.radioButton.size = buttonSize }
        }
    }

    @IBInspectable open dynamic var spacing: CGFloat = 8 {
        didSet {
            stackView.spacing = spacing
        }
    }

    @IBInspectable open dynamic var itemSpacing: CGFloat = 4 {
        didSet {
            forEachItem { $0.spacing = itemSpacing }
        }
    }

    @IBInspectable open dynamic var isButtonAfterTitle: Bool = false {
        didSet {
            let direction: UISemanticContentAttribute = isButtonAfterTitle ? .forceRightToLeft : .unspecified
            forEachItem { $0.semanticContentAttribute = direction }
        }
    }

    @IBInspectable open dynamic var titleColor: UIColor? {
        didSet {
            guard titleColor != oldValue else { return }
            forEachItem { $0.titleLabel.textColor = titleColor }
        }
    }

    @objc open dynamic var titleAlignment: NSTextAlignment = .natural {
        didSet {
            forEachItem { $0.titleLabel.textAlignment = titleAlignment }
        }
    }

    @objc open dynamic var titleFont: UIFont? {
        didSet {
            guard titleFont != oldValue else { return }
            let newFont = titleFont ?? UIFont.systemFont(ofSize: UIFont.labelFontSize)
            forEachItem { $0.titleLabel.font = newFont }
        }
    }

    // MARK: - Private

    private let stackView = UIStackView()
    private var items: [RadioGroupItem] {
        return stackView.arrangedSubviews.compactMap { $0 as? RadioGroupItem }
    }

    private func setup() {
        addSubview(stackView)
        NSLayoutConstraint.activate(stackView.constraintsToSuper())
        
        stackView.distribution = .equalSpacing
        setContentCompressionResistancePriority(.required, for: .vertical)
        isVertical = { isVertical }()
        spacing = { spacing }()
        accessibilityIdentifier = "RadioGroup"
    }

    private func updateAllItems() {
        selectedColor = { selectedColor }()
        selectedTintColor = { selectedTintColor }()
        buttonSize = { buttonSize }()
        itemSpacing = { itemSpacing }()
        isButtonAfterTitle = { isButtonAfterTitle }()
        titleAlignment = { titleAlignment }()
        selectedIndex = { selectedIndex }()
    }

    private func item(at index: Int) -> RadioGroupItem? {
        guard index >= 0 && index < stackView.arrangedSubviews.count else { return nil }
        return stackView.arrangedSubviews[index] as? RadioGroupItem
    }

    private func forEachItem(_ perform: (RadioGroupItem) -> Void) {
        items.forEach(perform)
    }

    func selectIndex(item: RadioGroupItem) {
        guard let index = stackView.arrangedSubviews.firstIndex(of: item) else { return }
        selectedIndex = index
        sendActions(for: [.valueChanged, .primaryActionTriggered])
    }

    // MARK: - Overrides

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    open override var intrinsicContentSize: CGSize {
        var size = stackView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        size.width += layoutMargins.left + layoutMargins.right
        size.height += layoutMargins.top + layoutMargins.bottom
        return size
    }

    open override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        titles = ["First Option", "Second Option", "Third"]
    }
}

class RadioGroupItem: UIStackView {
    let titleLabel = UILabel()
    let radioButton = RadioButton()

    unowned var group: RadioGroup

    init(title: String?, group: RadioGroup) {
        self.group = group
        super.init(frame: .zero)
        titleLabel.text = title
        setup()
    }

    init(attributedTitle: NSAttributedString?, group: RadioGroup) {
        self.group = group
        super.init(frame: .zero)
        titleLabel.attributedText = attributedTitle
        setup()
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        titleLabel.numberOfLines = 0
        titleLabel.lineBreakMode = .byWordWrapping
        if let titleFont = group.titleFont {
            titleLabel.font = titleFont
        }
        if let titleColor = group.titleColor {
            titleLabel.textColor = titleColor
        }
        
        addArrangedSubviews([radioButton, titleLabel])
        alignment = .center

        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didSelect)))

        isAccessibilityElement = true
        accessibilityLabel = "option"
        accessibilityValue = titleLabel.text
        accessibilityIdentifier = "RadioGroupItem"
    }

    @objc func didSelect() {
        group.selectIndex(item: self)
    }

    override var accessibilityTraits: UIAccessibilityTraits {
        get {
            return radioButton.isSelected ? [.selected] : []
        }
        set {} // swiftlint:disable:this unused_setter_value
    }
}

internal extension UIStackView {
    
    func addArrangedSubviews(_ subviews: [UIView]) {
        for subview in subviews {
            addArrangedSubview(subview)
        }
    }
    
    func removeArrangedSubviewCompletely(_ subview: UIView) {
        removeArrangedSubview(subview)
        subview.removeFromSuperview()
    }

    func removeAllArrangedSubviewsCompletely() {
        for subview in arrangedSubviews.reversed() {
            removeArrangedSubviewCompletely(subview)
        }
    }
}

internal extension UIView {
    
    var actualTintColor: UIColor {
        var tintedView: UIView? = self
        while let currentView = tintedView, nil == currentView.tintColor {
            tintedView = currentView.superview
        }
        return tintedView?.tintColor ?? UIColor(red: 0, green: 0.5, blue: 1, alpha: 1)
    }
    
    func addConstraintWithoutConflict(_ constraint: NSLayoutConstraint) {
        removeConstraints(constraints.filter {
            constraint.firstItem === $0.firstItem
                && constraint.secondItem === $0.secondItem
                && constraint.firstAttribute == $0.firstAttribute
                && constraint.secondAttribute == $0.secondAttribute
        })
        addConstraint(constraint)
    }
    
    func leftToSuper(relation: NSLayoutConstraint.Relation = .equal, constant: CGFloat) -> NSLayoutConstraint {
        guard let superView = self.superview else { fatalError() }
        
        self.translatesAutoresizingMaskIntoConstraints = false
        
        return NSLayoutConstraint(item: self, attribute: .leading, relatedBy: relation, toItem: superView, attribute: .leading, multiplier: 1, constant: constant)
    }
    
    func rightToSuper(relation: NSLayoutConstraint.Relation = .equal, constant: CGFloat) -> NSLayoutConstraint {
        guard let superView = self.superview else { fatalError() }
        
        self.translatesAutoresizingMaskIntoConstraints = false
        
        return NSLayoutConstraint(item: superView, attribute: .trailing, relatedBy: relation, toItem: self, attribute: .trailing, multiplier: 1, constant: constant)
    }
    
    func topToSuper(relation: NSLayoutConstraint.Relation = .equal, constant: CGFloat) -> NSLayoutConstraint {
        guard let superView = self.superview else { fatalError() }
        
        self.translatesAutoresizingMaskIntoConstraints = false
        
        return NSLayoutConstraint(item: self, attribute: .top, relatedBy: relation, toItem: superView, attribute: .top, multiplier: 1, constant: constant)
    }
    
    func bottomToSuper(relation: NSLayoutConstraint.Relation = .equal, constant: CGFloat) -> NSLayoutConstraint {
        guard let superView = self.superview else { fatalError() }
        
        self.translatesAutoresizingMaskIntoConstraints = false
        
        return NSLayoutConstraint(item: superView, attribute: .bottom, relatedBy: relation, toItem: self, attribute: .bottom, multiplier: 1, constant: constant)
    }
    
    func constraintsToSuper(_ constant: CGFloat = 0) -> [NSLayoutConstraint] {
        let top = topToSuper(constant: constant)
        let left = leftToSuper(constant: constant)
        let bottom = bottomToSuper(constant: constant)
        let right = rightToSuper(constant: constant)
        return [top, left, bottom, right].compactMap({ $0 })
    }
    
    func widthConstraint(_ constant: CGFloat, relation: NSLayoutConstraint.Relation = .equal)  -> NSLayoutConstraint {
        self.translatesAutoresizingMaskIntoConstraints = false
        return NSLayoutConstraint(item: self, attribute: .width, relatedBy: relation, toItem: nil, attribute: .width, multiplier: 1, constant: constant)
    }
    
    func heightConstraint(_ constant: CGFloat, relation: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint {
        self.translatesAutoresizingMaskIntoConstraints = false
        return NSLayoutConstraint(item: self, attribute: .height, relatedBy: relation, toItem: nil, attribute: .height, multiplier: 1, constant: constant)
    }
    
    func constraint(
        attribute firstAttribute: NSLayoutConstraint.Attribute,
        to view: UIView,
        attribute secondAttribute: NSLayoutConstraint.Attribute,
        multiplier: CGFloat = 1,
        constant: CGFloat = 0
    ) -> NSLayoutConstraint {
        self.translatesAutoresizingMaskIntoConstraints = false
        return NSLayoutConstraint(
            item: self,
            attribute: firstAttribute,
            relatedBy: .equal,
            toItem: view,
            attribute: secondAttribute,
            multiplier: multiplier,
            constant: constant
        )
    }
}

//
//  DigimonTableViewCell.swift
//  DigimonTamers
//
//  Created by Gabriel Bruno Meira on 28/07/25.
//

import UIKit

class DigimonTableViewCell: UITableViewCell {
    static let identifier = "DigimonTableViewCell"
    
    // MARK: - UI Elements
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 16
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4
        view.layer.shadowOpacity = 0.1
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let digimonImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .clear
        imageView.layer.cornerRadius = 8
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = .label
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let numberLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .secondaryLabel
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        contentView.addSubview(containerView)
        containerView.addSubview(digimonImageView)
        containerView.addSubview(nameLabel)
        containerView.addSubview(numberLabel)
        containerView.addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            // Container View
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            containerView.heightAnchor.constraint(equalToConstant: 100),
            
            // Digimon Image
            digimonImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            digimonImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            digimonImageView.widthAnchor.constraint(equalToConstant: 80),
            digimonImageView.heightAnchor.constraint(equalToConstant: 80),
            
            // Name Label
            nameLabel.leadingAnchor.constraint(equalTo: digimonImageView.trailingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            nameLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            
            // Number Label
            numberLabel.leadingAnchor.constraint(equalTo: digimonImageView.trailingAnchor, constant: 16),
            numberLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            numberLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            
            // Activity Indicator
            activityIndicator.centerXAnchor.constraint(equalTo: digimonImageView.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: digimonImageView.centerYAnchor)
        ])
    }
    
    // MARK: - Configure Cell
    func configure(with digimon: DigimonBasic) {
        nameLabel.text = digimon.name
        numberLabel.text = String(format: "#%03d", digimon.id)
        
        // Reset image
        digimonImageView.image = UIImage(systemName: "photo")
        activityIndicator.startAnimating()
        
        // Load image with better error handling
        NetworkManager.shared.downloadImage(from: digimon.image) { [weak self] image in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.activityIndicator.stopAnimating()
                
                if let image = image {
                    self.digimonImageView.image = image
                } else {
                    // Use a system image as fallback
                    self.digimonImageView.image = UIImage(systemName: "questionmark.circle")
                }
            }
        }
    }
    
    // MARK: - Prepare for Reuse
    override func prepareForReuse() {
        super.prepareForReuse()
        digimonImageView.image = nil
        nameLabel.text = nil
        numberLabel.text = nil
        activityIndicator.stopAnimating()
    }
}

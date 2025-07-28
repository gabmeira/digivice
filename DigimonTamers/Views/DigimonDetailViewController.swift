//
//  DigimonDetailViewController.swift
//  DigimonTamers
//
//  Created by Gabriel Bruno Meira on 28/07/25.
//

import UIKit

class DigimonDetailViewController: UIViewController {
    
    // MARK: - Properties
    private let digimonId: Int
    private var digimonDetail: DigimonDetail?
    
    // MARK: - UI Elements
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let digimonImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .clear
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 32, weight: .bold)
        label.textColor = .label
        label.textAlignment = .center
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let numberLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .medium)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let infoStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.distribution = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    // MARK: - Initialization
    init(digimonId: Int) {
        self.digimonId = digimonId
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadDigimonDetail()
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        view.backgroundColor = .systemBackground
        navigationItem.largeTitleDisplayMode = .never
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(digimonImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(numberLabel)
        contentView.addSubview(infoStackView)
        view.addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            // Scroll View
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Content View
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Digimon Image
            digimonImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            digimonImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            digimonImageView.widthAnchor.constraint(equalToConstant: 200),
            digimonImageView.heightAnchor.constraint(equalToConstant: 200),
            
            // Name Label
            nameLabel.topAnchor.constraint(equalTo: digimonImageView.bottomAnchor, constant: 16),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Number Label
            numberLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 8),
            numberLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            numberLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Info Stack View
            infoStackView.topAnchor.constraint(equalTo: numberLabel.bottomAnchor, constant: 24),
            infoStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            infoStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            infoStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            
            // Activity Indicator
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    // MARK: - Data Loading
    private func loadDigimonDetail() {
        activityIndicator.startAnimating()
        
        NetworkManager.shared.fetchDigimonDetail(id: digimonId) { [weak self] result in
            DispatchQueue.main.async {
                self?.activityIndicator.stopAnimating()
                
                switch result {
                case .success(let detail):
                    self?.digimonDetail = detail
                    self?.configureDetailView(with: detail)
                    
                case .failure(let error):
                    self?.showError(error.localizedDescription)
                }
            }
        }
    }
    
    // MARK: - Configure Detail View
    private func configureDetailView(with detail: DigimonDetail) {
        nameLabel.text = detail.name
        numberLabel.text = String(format: "#%03d", detail.id)
        
        // Load image
        if let imageURL = detail.images.first?.href {
            NetworkManager.shared.downloadImage(from: imageURL) { [weak self] image in
                DispatchQueue.main.async {
                    self?.digimonImageView.image = image ?? UIImage(systemName: "photo")
                }
            }
        }
        
        // Clear existing info
        infoStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // Add info sections
        addInfoSection(title: "Nível", value: detail.levels.first?.level ?? "Desconhecido")
        addInfoSection(title: "Tipo", value: detail.types.first?.type ?? "Desconhecido")
        addInfoSection(title: "Atributo", value: detail.attributes.first?.attribute ?? "Desconhecido")
        addInfoSection(title: "Ano de Lançamento", value: detail.releaseDate)
        
        // Add description
        if let description = detail.descriptions.first(where: { $0.language == "en_us" }) {
            addDescriptionSection(description: description.description)
        }
    }
    
    // MARK: - Helper Methods
    private func addInfoSection(title: String, value: String) {
        let containerView = UIView()
        containerView.backgroundColor = .secondarySystemBackground
        containerView.layer.cornerRadius = 12
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.text = title
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let valueLabel = UILabel()
        valueLabel.font = .systemFont(ofSize: 16, weight: .regular)
        valueLabel.textColor = .secondaryLabel
        valueLabel.text = value
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(titleLabel)
        containerView.addSubview(valueLabel)
        
        NSLayoutConstraint.activate([
            containerView.heightAnchor.constraint(equalToConstant: 60),
            
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            
            valueLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            valueLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            valueLabel.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 8)
        ])
        
        infoStackView.addArrangedSubview(containerView)
    }
    
    private func addDescriptionSection(description: String) {
        let containerView = UIView()
        containerView.backgroundColor = .secondarySystemBackground
        containerView.layer.cornerRadius = 12
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.text = "Descrição"
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let descriptionLabel = UILabel()
        descriptionLabel.font = .systemFont(ofSize: 14, weight: .regular)
        descriptionLabel.textColor = .secondaryLabel
        descriptionLabel.text = description
        descriptionLabel.numberOfLines = 0
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(titleLabel)
        containerView.addSubview(descriptionLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            descriptionLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            descriptionLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            descriptionLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16)
        ])
        
        infoStackView.addArrangedSubview(containerView)
    }
    
    // MARK: - Error Handling
    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Erro", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        })
        present(alert, animated: true)
    }
}

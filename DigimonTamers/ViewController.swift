//
//  ViewController.swift
//  DigimonTamers
//
//  Created by Gabriel Bruno Meira on 22/05/25.
//

import UIKit

class ViewController: UIViewController {
    
    // MARK: - Properties
    private var digimons: [DigimonBasic] = []
    private var filteredDigimons: [DigimonBasic] = []
    private var currentPage = 0
    private var isLoading = false
    private var hasMorePages = true
    private var isSearching = false
    private var searchController: UISearchController!
    
    // MARK: - UI Elements
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = .systemGroupedBackground
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        print("🚀 ViewController viewDidLoad called")
        
        // Inicializar arrays
        filteredDigimons = digimons
        
        setupUI()
        
        // Adicionar um delay para garantir que a UI esteja pronta
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            print("🚀 Starting loadDigimons after delay")
            self.loadDigimons()
        }
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        view.backgroundColor = .systemGroupedBackground
        title = "Digimons"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        // Setup Search Controller
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.delegate = self
        searchController.searchBar.delegate = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Buscar Digimon por nome"
        searchController.searchBar.searchBarStyle = .minimal
        
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
        
        // Setup table view
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(DigimonTableViewCell.self, forCellReuseIdentifier: DigimonTableViewCell.identifier)
        
        // Add subviews
        view.addSubview(tableView)
        view.addSubview(activityIndicator)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            // Table View
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Activity Indicator
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    // MARK: - Data Loading
    private func loadDigimons() {
        print("🔄 loadDigimons called - isLoading: \(isLoading), hasMorePages: \(hasMorePages), currentPage: \(currentPage)")
        guard !isLoading && hasMorePages else { 
            print("⚠️ Skipping load - isLoading: \(isLoading), hasMorePages: \(hasMorePages)")
            return 
        }
        
        isLoading = true
        print("🔄 Starting to load page \(currentPage)")
        
        // Mostrar indicator apenas na primeira carga ou quando não há dados
        if digimons.isEmpty {
            print("🔄 First load - showing activity indicator")
            activityIndicator.startAnimating()
        } else {
            print("🔄 Loading more pages - page \(currentPage)")
        }
        
        NetworkManager.shared.fetchDigimonList(page: currentPage, pageSize: 20) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false // IMPORTANTE: Resetar isLoading em ambos os casos
                self?.activityIndicator.stopAnimating()
                
                switch result {
                case .success(let response):
                    print("✅ Received \(response.content.count) digimons for page \(self?.currentPage ?? -1)")
                    print("📄 Page info - current: \(response.pageable.currentPage), total pages: \(response.pageable.totalPages)")
                    
                    self?.digimons.append(contentsOf: response.content)
                    self?.currentPage += 1
                    self?.hasMorePages = self?.currentPage ?? 0 < response.pageable.totalPages
                    
                    print("📊 Total digimons: \(self?.digimons.count ?? 0), hasMorePages: \(self?.hasMorePages ?? false)")
                    
                    // Atualizar filteredDigimons se não estiver buscando
                    if !(self?.isSearching ?? false) {
                        self?.filteredDigimons = self?.digimons ?? []
                    }
                    
                    self?.tableView.reloadData()
                    
                case .failure(let error):
                    print("❌ Error loading digimons: \(error.localizedDescription)")
                    // Resetar estado para permitir retry
                    self?.isLoading = false
                    self?.showErrorWithRetry(error.localizedDescription)
                }
            }
        }
    }
    
    // MARK: - Search Functionality
    private func filterDigimons(for searchText: String) {
        if searchText.isEmpty {
            filteredDigimons = digimons
            isSearching = false
        } else {
            // Primeiro fazer busca local
            filteredDigimons = digimons.filter { digimon in
                digimon.name.lowercased().contains(searchText.lowercased())
            }
            isSearching = true
            
            // Se não encontrou resultados locais e tem mais de 2 caracteres, buscar na API
            if filteredDigimons.isEmpty && searchText.count >= 2 {
                searchInAPI(for: searchText)
            }
        }
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    private func searchInAPI(for searchText: String) {
        print("🔍 Searching in API for: '\(searchText)'")
        activityIndicator.startAnimating()
        
        NetworkManager.shared.searchDigimonByName(searchText) { [weak self] result in
            DispatchQueue.main.async {
                self?.activityIndicator.stopAnimating()
                
                switch result {
                case .success(let response):
                    print("🔍 Found \(response.content.count) digimons in API search")
                    self?.filteredDigimons = response.content
                    self?.tableView.reloadData()
                    
                case .failure(let error):
                    print("❌ API search failed: \(error.localizedDescription)")
                    // Manter os resultados da busca local se a API falhar
                }
            }
        }
    }
    
    private func getCurrentDigimons() -> [DigimonBasic] {
        return isSearching ? filteredDigimons : digimons
    }
    
    // MARK: - Error Handling
    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Erro", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func showErrorWithRetry(_ message: String) {
        let alert = UIAlertController(title: "Erro de Conexão", message: "\(message)\n\nVerifique sua conexão com a internet.", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Tentar Novamente", style: .default) { [weak self] _ in
            print("🔄 User requested retry")
            self?.loadDigimons()
        })
        
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource
extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = getCurrentDigimons().count
        print("📊 Table view showing \(count) digimons (isSearching: \(isSearching))")
        return count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: DigimonTableViewCell.identifier, for: indexPath) as? DigimonTableViewCell else {
            return UITableViewCell()
        }
        
        let currentDigimons = getCurrentDigimons()
        guard indexPath.row < currentDigimons.count else {
            return UITableViewCell()
        }
        
        let digimon = currentDigimons[indexPath.row]
        cell.configure(with: digimon)
        
        return cell
    }
}

// MARK: - UITableViewDelegate
extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 116 // 100 + 16 (top and bottom margins)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let currentDigimons = getCurrentDigimons()
        guard indexPath.row < currentDigimons.count else { return }
        
        let digimon = currentDigimons[indexPath.row]
        let detailVC = DigimonDetailViewController(digimonId: digimon.id)
        navigationController?.pushViewController(detailVC, animated: true)
    }
    
    // MARK: - Pagination
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Só fazer paginação se não estiver buscando
        guard !isSearching else { 
            print("📜 Scroll ignored - searching active")
            return 
        }
        
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let height = scrollView.frame.size.height
        
        // Log para debug
        let threshold = contentHeight - height - 100
        if offsetY > threshold && !isLoading && hasMorePages {
            print("📜 Scroll triggered pagination - offsetY: \(offsetY), threshold: \(threshold)")
            loadDigimons()
        }
    }
}

// MARK: - UISearchResultsUpdating
extension ViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text else { return }
        print("🔍 Search text changed: '\(searchText)'")
        filterDigimons(for: searchText)
    }
}

// MARK: - UISearchControllerDelegate
extension ViewController: UISearchControllerDelegate {
    func willPresentSearchController(_ searchController: UISearchController) {
        print("🔍 Search will present")
    }
    
    func didPresentSearchController(_ searchController: UISearchController) {
        print("🔍 Search did present")
    }
    
    func willDismissSearchController(_ searchController: UISearchController) {
        print("🔍 Search will dismiss")
    }
    
    func didDismissSearchController(_ searchController: UISearchController) {
        print("🔍 Search did dismiss")
        // Resetar para mostrar todos os digimons
        isSearching = false
        filteredDigimons = digimons
        tableView.reloadData()
    }
}

// MARK: - UISearchBarDelegate
extension ViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        print("🔍 Search bar text did change: '\(searchText)'")
        filterDigimons(for: searchText)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        print("🔍 Search cancelled")
        isSearching = false
        filteredDigimons = digimons
        tableView.reloadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        print("🔍 Search button clicked")
        searchBar.resignFirstResponder()
    }
}


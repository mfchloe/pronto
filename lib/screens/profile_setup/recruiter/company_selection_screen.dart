import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pronto/widgets/custom_text_field.dart';
import 'package:pronto/constants.dart';
import 'create_company_screen.dart';
import 'package:pronto/widgets/navbar.dart';
import 'package:pronto/models/userType_model.dart';

class CompanySelectionScreen extends StatefulWidget {
  final String? recruiterId;

  const CompanySelectionScreen({super.key, required this.recruiterId});

  @override
  State<CompanySelectionScreen> createState() => _CompanySelectionScreenState();
}

class _CompanySelectionScreenState extends State<CompanySelectionScreen> {
  final _searchController = TextEditingController();
  List<DocumentSnapshot> _searchResults = [];
  bool _isSearching = false;
  bool _isLoading = false;
  String? _selectedCompanyId;
  Map<String, dynamic>? _selectedCompany;
  bool _showCreateCompany = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchCompanies(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _showCreateCompany = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final lowercaseQuery = query.trim().toLowerCase();

      // Option 2: Contains-based search - fetch all companies and filter locally
      final results = await FirebaseFirestore.instance
          .collection('companies')
          .get();

      final filteredDocs = results.docs
          .where((doc) {
            final data = doc.data();

            // Try both nameLower and name fields for more robust search
            final nameLower = data['nameLower'] as String? ?? '';
            final name = (data['name'] as String? ?? '').toLowerCase();

            final matchesNameLower = nameLower.contains(lowercaseQuery);
            final matchesName = name.contains(lowercaseQuery);

            return matchesNameLower || matchesName;
          })
          .take(10)
          .toList();

      setState(() {
        _searchResults = filteredDocs;
        _isSearching = false;
        _showCreateCompany = query.trim().isNotEmpty;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
        _showCreateCompany = query.trim().isNotEmpty;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error searching companies')),
        );
      }
    }
  }

  String _extractDomainFromEmail(String email) {
    return email.split('@').last.toLowerCase();
  }

  bool _validateEmailDomain(String companyDomain) {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.email == null) return false;

    final userDomain = _extractDomainFromEmail(user!.email!);
    return userDomain == companyDomain.toLowerCase();
  }

  Future<void> _selectCompany() async {
    if (_selectedCompanyId == null || _selectedCompany == null) return;

    // Validate email domain
    final companyDomain = _selectedCompany!['domain'] as String?;
    if (companyDomain != null && !_validateEmailDomain(companyDomain)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Your email domain must match the company domain (@$companyDomain)',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Update recruiter document with company information
      await FirebaseFirestore.instance
          .collection('recruiters')
          .doc(widget.recruiterId)
          .update({
            'companyId': _selectedCompanyId,
            'isVerified': false, // Can be verified later by admin
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        // Navigate to home
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account setup completed successfully!'),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => NavBar(
              userId: widget.recruiterId!,
              userType: UserType.recruiter,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Error completing setup')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(automaticallyImplyLeading: false),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Find Your Company',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 28,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Search for your company or create a new one',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 32),

              // Search field with left-side icon
              CustomTextField(
                controller: _searchController,
                label: 'Search company name',
                onChanged: _searchCompanies,
                prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
                suffixIcon: _isSearching
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
              ),
              const SizedBox(height: 24),

              // Search results or empty state
              if (_isSearching) ...[
                const SizedBox(height: 100),
                const Center(child: CircularProgressIndicator()),
                const SizedBox(height: 100),
              ] else if (_searchController.text.isEmpty) ...[
                SizedBox(
                  height: 200,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.business,
                          size: 64,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Start typing to search for companies',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                // Existing companies section
                if (_searchResults.isNotEmpty) ...[
                  Text(
                    'Existing Companies',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Company list
                  ...List.generate(_searchResults.length, (index) {
                    final company = _searchResults[index];
                    final companyData = company.data() as Map<String, dynamic>;
                    final isSelected = _selectedCompanyId == company.id;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Card(
                        elevation: isSelected ? 4 : 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: isSelected
                              ? BorderSide(color: AppColors.primary, width: 2)
                              : BorderSide.none,
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: CircleAvatar(
                            radius: 24,
                            backgroundColor: AppColors.primary.withOpacity(0.1),
                            child: companyData['logoUrl'] != null
                                ? ClipOval(
                                    child: Image.network(
                                      companyData['logoUrl'],
                                      width: 48,
                                      height: 48,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Icon(
                                              Icons.business,
                                              color: AppColors.primary,
                                              size: 24,
                                            );
                                          },
                                    ),
                                  )
                                : Icon(
                                    Icons.business,
                                    color: AppColors.primary,
                                    size: 24,
                                  ),
                          ),
                          title: Text(
                            companyData['name'] ?? 'Unknown Company',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                companyData['industry'] ??
                                    'No industry specified',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              if (companyData['domain'] != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  '@${companyData['domain']}',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          trailing: isSelected
                              ? Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                )
                              : null,
                          onTap: () {
                            setState(() {
                              if (_selectedCompanyId == company.id) {
                                // Deselect if already selected
                                _selectedCompanyId = null;
                                _selectedCompany = null;
                              } else {
                                // Select this company
                                _selectedCompanyId = company.id;
                                _selectedCompany = companyData;
                              }
                            });
                          },
                        ),
                      ),
                    );
                  }),
                ],

                // Create new company option
                if (_showCreateCompany) ...[
                  if (_searchResults.isNotEmpty) ...[const Divider()],
                  Text(
                    _searchResults.isEmpty
                        ? 'No companies found'
                        : 'Or create new',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: AppColors.primary.withOpacity(0.3),
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.add_business,
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ),
                      title: Text(
                        'Create "${_searchController.text}"',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      subtitle: Text(
                        'Add a new company to the platform',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        color: AppColors.primary,
                        size: 16,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CreateCompanyScreen(
                              recruiterId: widget.recruiterId,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],

              const SizedBox(height: 24),

              // Continue/Finish button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedCompanyId != null && !_isLoading
                      ? _selectCompany
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _selectedCompanyId != null
                              ? 'Continue with Selected Company'
                              : 'Select a Company',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),

              // Add some bottom padding for better scroll experience
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

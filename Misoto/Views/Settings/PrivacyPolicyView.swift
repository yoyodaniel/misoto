//
//  PrivacyPolicyView.swift
//  Misoto
//
//  Created by Daniel Chan on 30.12.2025.
//

import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Introduction
                    SectionView(title: LocalizedString("Our Commitment to Your Privacy", comment: "Privacy policy introduction")) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(LocalizedString("At Misoto, we understand that your privacy is important. This Privacy Policy explains how we collect, use, protect, and share your information when you use the Misoto mobile application (the \"App\" or \"Service\").", comment: "Privacy policy intro 1"))
                            Text(LocalizedString("We are committed to being transparent about our data practices and giving you control over your personal information. Please take the time to read this Privacy Policy carefully to understand our practices.", comment: "Privacy policy intro 2"))
                            Text(LocalizedString("By using the App, you agree to the collection and use of information as described in this Privacy Policy. If you do not agree with our practices, please do not use the App.", comment: "Privacy policy agreement"))
                        }
                        .font(.body)
                    }
                    
                    // What We Collect
                    SectionView(title: LocalizedString("What Information We Collect", comment: "Information collection section")) {
                        VStack(alignment: .leading, spacing: 16) {
                            // Account Data
                            VStack(alignment: .leading, spacing: 8) {
                                Text(LocalizedString("Account and Profile Information", comment: "Account info subsection"))
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                Text(LocalizedString("When you create an account, we collect information that you provide, such as:", comment: "Account info intro"))
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("• " + LocalizedString("Your email address (when using Google Sign-In)", comment: "Email"))
                                    Text("• " + LocalizedString("Your name and chosen username", comment: "Name"))
                                    Text("• " + LocalizedString("Profile photo (if you choose to upload one)", comment: "Profile photo"))
                                    Text("• " + LocalizedString("Biography or description (optional)", comment: "Bio"))
                                    Text("• " + LocalizedString("Privacy preferences (public, limited, or private profile settings)", comment: "Privacy prefs"))
                                }
                                .padding(.leading, 16)
                            }
                            
                            // Recipe Data
                            VStack(alignment: .leading, spacing: 8) {
                                Text(LocalizedString("Recipe and Content Information", comment: "Recipe info subsection"))
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                Text(LocalizedString("When you create or share recipes, we collect:", comment: "Recipe info intro"))
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("• " + LocalizedString("Recipe details including titles, descriptions, ingredients, and cooking instructions", comment: "Recipe content"))
                                    Text("• " + LocalizedString("Recipe metadata such as cooking times, servings, difficulty level, cuisine type, and spice level", comment: "Recipe metadata"))
                                    Text("• " + LocalizedString("Images associated with recipes (main photos and step-by-step photos)", comment: "Recipe images"))
                                    Text("• " + LocalizedString("Source images used for recipe extraction (photos of books, websites, etc.)", comment: "Source images"))
                                    Text("• " + LocalizedString("Video content if you upload cooking instruction videos", comment: "Videos"))
                                    Text("• " + LocalizedString("Tips, notes, and additional information you add to recipes", comment: "Tips"))
                                }
                                .padding(.leading, 16)
                            }
                            
                            // Notes Data
                            VStack(alignment: .leading, spacing: 8) {
                                Text(LocalizedString("Personal Notes", comment: "Notes subsection"))
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                Text(LocalizedString("When you add notes to recipes, we store:", comment: "Notes intro"))
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("• " + LocalizedString("The text content of your notes", comment: "Note content"))
                                    Text("• " + LocalizedString("When notes were created or last modified", comment: "Note dates"))
                                    Text("• " + LocalizedString("Which recipes your notes are associated with", comment: "Note association"))
                                }
                                .padding(.leading, 16)
                            }
                            
                            // Social Data
                            VStack(alignment: .leading, spacing: 8) {
                                Text(LocalizedString("Social and Engagement Information", comment: "Social info subsection"))
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                Text(LocalizedString("When you interact with other users or content, we collect:", comment: "Social info intro"))
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("• " + LocalizedString("Recipes you mark as favorites", comment: "Favorites"))
                                    Text("• " + LocalizedString("Users you follow and users who follow you", comment: "Follows"))
                                    Text("• " + LocalizedString("Engagement statistics and activity data", comment: "Engagement"))
                                }
                                .padding(.leading, 16)
                            }
                            
                            // Subscription Data
                            VStack(alignment: .leading, spacing: 8) {
                                Text(LocalizedString("Subscription and Payment Information", comment: "Subscription info subsection"))
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                Text(LocalizedString("When you purchase a Premium subscription, we collect:", comment: "Subscription info intro"))
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("• " + LocalizedString("Subscription tier (Premium Monthly or Premium Yearly)", comment: "Subscription tier"))
                                    Text("• " + LocalizedString("Subscription status and expiration date", comment: "Subscription status"))
                                    Text("• " + LocalizedString("Transaction identifiers from Apple's StoreKit (for subscription verification)", comment: "Transaction ID"))
                                    Text("• " + LocalizedString("Purchase and renewal dates", comment: "Purchase dates"))
                                }
                                .padding(.leading, 16)
                                Text(LocalizedString("Important: We do not collect or store your payment information. All payments are processed through Apple's App Store using StoreKit. Apple handles all payment processing, and we only receive transaction confirmations and subscription status information.", comment: "Payment processing disclaimer"))
                                    .fontWeight(.medium)
                                    .padding(.top, 4)
                            }
                            
                            // Usage Tracking Data
                            VStack(alignment: .leading, spacing: 8) {
                                Text(LocalizedString("Usage Tracking Information", comment: "Usage tracking subsection"))
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                Text(LocalizedString("To enforce free tier limits and provide subscription features, we track:", comment: "Usage tracking intro"))
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("• " + LocalizedString("Number of recipes created per month", comment: "Recipe count tracking"))
                                    Text("• " + LocalizedString("Number of AI-powered recipe extractions performed per month", comment: "AI extraction tracking"))
                                    Text("• " + LocalizedString("Number of AI-generated recipe descriptions created per month", comment: "AI description tracking"))
                                    Text("• " + LocalizedString("Monthly usage reset dates", comment: "Reset dates"))
                                }
                                .padding(.leading, 16)
                                Text(LocalizedString("This information is used solely to enforce subscription limits and is not shared with third parties except as necessary to provide the Service.", comment: "Usage tracking purpose"))
                                    .fontWeight(.medium)
                                    .padding(.top, 4)
                            }
                            
                            // Technical Data
                            VStack(alignment: .leading, spacing: 8) {
                                Text(LocalizedString("Technical and Usage Information", comment: "Technical info subsection"))
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                Text(LocalizedString("We automatically collect certain technical information when you use the App:", comment: "Technical info intro"))
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("• " + LocalizedString("Device type and operating system version", comment: "Device info"))
                                    Text("• " + LocalizedString("App version and installation information", comment: "App version"))
                                    Text("• " + LocalizedString("How you authenticate (Google Sign-In or Apple Sign-In)", comment: "Auth method"))
                                    Text("• " + LocalizedString("Error reports and performance data (if enabled)", comment: "Error data"))
                                }
                                .padding(.leading, 16)
                            }
                            
                            // Feedback Data
                            VStack(alignment: .leading, spacing: 8) {
                                Text(LocalizedString("Feedback and Communications", comment: "Feedback subsection"))
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                Text(LocalizedString("If you contact us or submit feedback, we may collect:", comment: "Feedback intro"))
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("• " + LocalizedString("The content of your messages, feedback, or feature requests", comment: "Feedback content"))
                                    Text("• " + LocalizedString("Your email address (if you provide it for follow-up)", comment: "Feedback email"))
                                    Text("• " + LocalizedString("Technical information about the App version you're using", comment: "Feedback metadata"))
                                }
                                .padding(.leading, 16)
                            }
                            
                            // Device Permissions
                            VStack(alignment: .leading, spacing: 8) {
                                Text(LocalizedString("Device Permissions", comment: "Permissions subsection"))
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                Text(LocalizedString("The App requests access to:", comment: "Permissions intro"))
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("• " + LocalizedString("Camera - To take photos of recipes for extraction. Images are processed by AI services to extract recipe information.", comment: "Camera permission"))
                                    Text("• " + LocalizedString("Photo Library - To select existing images for recipe extraction or to use as recipe photos. Selected images are sent to AI services for processing.", comment: "Photo library permission"))
                                }
                                .padding(.leading, 16)
                                Text(LocalizedString("You can manage these permissions through your device settings. Note that revoking permissions may limit some App features.", comment: "Permissions note"))
                            }
                        }
                        .font(.body)
                    }
                    
                    // How We Use Information
                    SectionView(title: LocalizedString("How We Use Your Information", comment: "Information usage section")) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(LocalizedString("We use the information we collect to provide, maintain, and improve the App. Specifically, we use your information to:", comment: "Usage intro"))
                            VStack(alignment: .leading, spacing: 8) {
                                Text("• " + LocalizedString("Deliver core App features including recipe management, sharing, and social interactions", comment: "Core features"))
                                Text("• " + LocalizedString("Process recipe extraction requests using AI services when you extract recipes from images or websites", comment: "AI processing"))
                                Text("• " + LocalizedString("Enable social features like following users, favoriting recipes, and discovering content", comment: "Social features"))
                                Text("• " + LocalizedString("Respect your privacy preferences and control who can see your profile and recipes", comment: "Privacy controls"))
                                Text("• " + LocalizedString("Authenticate your account and maintain account security", comment: "Security"))
                                Text("• " + LocalizedString("Manage subscriptions, verify subscription status, and enforce free tier usage limits", comment: "Subscription management"))
                                Text("• " + LocalizedString("Track usage to provide subscription features and limit enforcement", comment: "Usage tracking"))
                                Text("• " + LocalizedString("Respond to your questions, feedback, and support requests", comment: "Support"))
                                Text("• " + LocalizedString("Detect and prevent security threats, fraud, or misuse of the App", comment: "Threat prevention"))
                                Text("• " + LocalizedString("Improve the App's features, performance, and user experience", comment: "Improvements"))
                                Text("• " + LocalizedString("Comply with legal obligations and enforce our Terms of Service", comment: "Legal compliance"))
                            }
                            .padding(.leading, 16)
                        }
                        .font(.body)
                    }
                    
                    // Data Sharing
                    SectionView(title: LocalizedString("How We Share Your Information", comment: "Data sharing section")) {
                        VStack(alignment: .leading, spacing: 16) {
                            Text(LocalizedString("We do not sell your personal information. We share your information only in the following circumstances:", comment: "No sale"))
                                .fontWeight(.medium)
                            
                            // Service Providers
                            VStack(alignment: .leading, spacing: 8) {
                                Text(LocalizedString("Service Providers", comment: "Service providers subsection"))
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                Text(LocalizedString("We work with third-party service providers to operate the App:", comment: "Service providers intro"))
                                
                                Text(LocalizedString("Firebase (Google Cloud Platform)", comment: "Firebase header"))
                                    .fontWeight(.semibold)
                                Text(LocalizedString("We use Google's Firebase services to store and process your data:", comment: "Firebase intro"))
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("• " + LocalizedString("Firebase Authentication - Manages your account login and authentication", comment: "Firebase Auth"))
                                    Text("• " + LocalizedString("Cloud Firestore - Stores your recipes, notes, profile information, and other app data", comment: "Firestore"))
                                    Text("• " + LocalizedString("Firebase Storage - Hosts your images and uploaded files", comment: "Firebase Storage"))
                                }
                                .padding(.leading, 16)
                                Text(LocalizedString("Your data in Firebase is subject to Google's Privacy Policy. Firebase uses encryption and industry-standard security measures.", comment: "Firebase privacy"))
                                
                                Text(LocalizedString("OpenAI", comment: "OpenAI header"))
                                    .fontWeight(.semibold)
                                Text(LocalizedString("When you use recipe extraction features, we send images and text content to OpenAI for processing:", comment: "OpenAI intro"))
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("• " + LocalizedString("Images and content are analyzed to extract recipe information", comment: "OpenAI analysis"))
                                    Text("• " + LocalizedString("OpenAI's use of your content is governed by their Privacy Policy and Terms of Use", comment: "OpenAI terms"))
                                }
                                .padding(.leading, 16)
                                Text(LocalizedString("Important: You are responsible for ensuring you have the right to extract and use content from the sources you access. We are not responsible for copyright or intellectual property issues related to content you extract.", comment: "OpenAI disclaimer"))
                                    .fontWeight(.medium)
                                
                                Text(LocalizedString("Apple (StoreKit)", comment: "Apple StoreKit header"))
                                    .fontWeight(.semibold)
                                Text(LocalizedString("When you purchase a Premium subscription, Apple processes your payment through StoreKit:", comment: "StoreKit intro"))
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("• " + LocalizedString("Apple handles all payment processing and stores your payment information", comment: "Apple payment processing"))
                                    Text("• " + LocalizedString("We receive only transaction confirmations and subscription status from Apple", comment: "Transaction confirmations"))
                                    Text("• " + LocalizedString("Apple's use of your payment information is governed by Apple's Privacy Policy and Terms of Service", comment: "Apple terms"))
                                    Text("• " + LocalizedString("Subscription management (cancellation, renewal) is handled through Apple's systems", comment: "Subscription management"))
                                }
                                .padding(.leading, 16)
                            }
                            
                            // Legal Sharing
                            VStack(alignment: .leading, spacing: 8) {
                                Text(LocalizedString("Legal Requirements", comment: "Legal requirements subsection"))
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                Text(LocalizedString("We may disclose your information if required by law, court order, or government regulation, or if we believe disclosure is necessary to protect our rights, your safety, or the safety of others.", comment: "Legal disclosure"))
                            }
                            
                            // Business Transfers
                            VStack(alignment: .leading, spacing: 8) {
                                Text(LocalizedString("Business Transfers", comment: "Business transfers subsection"))
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                Text(LocalizedString("If Misoto is involved in a merger, acquisition, or sale of assets, your information may be transferred as part of that transaction. We will notify you of any such change in ownership or control.", comment: "Business transfers"))
                            }
                        }
                        .font(.body)
                    }
                    
                    // Data Security
                    SectionView(title: LocalizedString("How We Protect Your Information", comment: "Data security section")) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(LocalizedString("We implement security measures designed to protect your information:", comment: "Security intro"))
                            VStack(alignment: .leading, spacing: 8) {
                                Text("• " + LocalizedString("Encryption - Data is encrypted both in transit and at rest", comment: "Encryption"))
                                Text("• " + LocalizedString("Secure Authentication - We use industry-standard authentication methods (Google Sign-In and Apple Sign-In)", comment: "Auth security"))
                                Text("• " + LocalizedString("Access Controls - Database security rules ensure users can only access appropriate data", comment: "Access controls"))
                                Text("• " + LocalizedString("Regular Updates - We regularly review and update our security practices", comment: "Updates"))
                            }
                            .padding(.leading, 16)
                            Text(LocalizedString("However, no method of electronic transmission or storage is 100% secure. While we strive to protect your information, we cannot guarantee absolute security.", comment: "Security disclaimer"))
                        }
                        .font(.body)
                    }
                    
                    // User Rights
                    SectionView(title: LocalizedString("Your Privacy Rights", comment: "User rights section")) {
                        VStack(alignment: .leading, spacing: 16) {
                            Text(LocalizedString("Depending on where you live, you may have certain rights regarding your personal information. These may include:", comment: "Rights intro"))
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text(LocalizedString("Access and Review", comment: "Access right"))
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                Text(LocalizedString("You can view your account information, recipes, notes, and other data directly in the App.", comment: "Access explanation"))
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text(LocalizedString("Update and Correct", comment: "Update right"))
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                Text(LocalizedString("You can update your profile information, recipes, and notes at any time through the App's interface.", comment: "Update explanation"))
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text(LocalizedString("Delete Your Account", comment: "Delete right"))
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                Text(LocalizedString("You can delete your account at any time through Settings → Account → Delete Account. When you delete your account, we will remove:", comment: "Delete intro"))
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("• " + LocalizedString("Your account and profile information", comment: "Account deletion item"))
                                    Text("• " + LocalizedString("All your recipes and associated images", comment: "Recipes deletion item"))
                                    Text("• " + LocalizedString("All your personal notes", comment: "Notes deletion item"))
                                    Text("• " + LocalizedString("Your favorites and follow relationships", comment: "Social deletion item"))
                                }
                                .padding(.leading, 16)
                                Text(LocalizedString("Account deletion is permanent. Some information may be retained as required by law or for legitimate business purposes.", comment: "Deletion permanence"))
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text(LocalizedString("Privacy Controls", comment: "Privacy controls right"))
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                Text(LocalizedString("You can control your privacy through Settings → Account, including choosing whether your profile is public, limited, or private.", comment: "Privacy controls explanation"))
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text(LocalizedString("Device Permissions", comment: "Permissions right"))
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                Text(LocalizedString("You can manage camera and photo library permissions through your device settings. Revoking permissions may limit App functionality.", comment: "Permissions explanation"))
                            }
                            
                            Text(LocalizedString("To exercise any of these rights, please contact us at support@misoto.app. We will respond to your request within a reasonable timeframe.", comment: "Rights contact"))
                                .fontWeight(.medium)
                        }
                        .font(.body)
                    }
                    
                    // Data Retention
                    SectionView(title: LocalizedString("How Long We Keep Your Information", comment: "Data retention section")) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(LocalizedString("We retain your information for as long as necessary to provide the App and fulfill the purposes described in this Privacy Policy.", comment: "Retention general"))
                            Text(LocalizedString("Retention periods vary depending on the type of information:", comment: "Retention intro"))
                            VStack(alignment: .leading, spacing: 8) {
                                Text("• " + LocalizedString("Account Information - Until you delete your account", comment: "Account retention"))
                                Text("• " + LocalizedString("Recipes and Content - Until you delete your account or remove the content", comment: "Content retention"))
                                Text("• " + LocalizedString("Images and Files - Until you delete your account or remove the associated content", comment: "Files retention"))
                                Text("• " + LocalizedString("Subscription Information - Until you delete your account or as required by law for financial records", comment: "Subscription retention"))
                                Text("• " + LocalizedString("Usage Tracking Data - Until you delete your account or up to 2 years, whichever comes first", comment: "Usage tracking retention"))
                                Text("• " + LocalizedString("Usage Data - Up to 2 years or until account deletion", comment: "Usage retention"))
                                Text("• " + LocalizedString("Feedback - Up to 3 years for service improvement", comment: "Feedback retention"))
                            }
                            .padding(.leading, 16)
                            Text(LocalizedString("When you delete your account, we will remove your information within 30 days, except where we are required to retain it for legal purposes.", comment: "Deletion timeline"))
                        }
                        .font(.body)
                    }
                    
                    // Children's Privacy
                    SectionView(title: LocalizedString("Children's Privacy", comment: "Children's privacy section")) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(LocalizedString("The App is not intended for users under 16 years of age. We do not knowingly collect personal information from children under 16.", comment: "Children's privacy general"))
                            Text(LocalizedString("If you are a parent or guardian and believe your child has provided us with personal information, please contact us at support@misoto.app. If we discover we have collected information from a child under 16, we will delete it promptly.", comment: "Children's privacy contact"))
                            Text(LocalizedString("If you are between 16 and 18 years old, please ensure you have permission from a parent or guardian before using the App.", comment: "Minor permission"))
                        }
                        .font(.body)
                    }
                    
                    // International Transfers
                    SectionView(title: LocalizedString("International Data Transfers", comment: "International transfers section")) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(LocalizedString("Your information may be stored and processed in countries other than your country of residence, including the United States and other locations where our service providers operate.", comment: "International transfers general"))
                            Text(LocalizedString("These countries may have different data protection laws than your country. By using the App, you consent to the transfer of your information to these countries.", comment: "International transfers consent"))
                            Text(LocalizedString("We take steps to ensure your information receives appropriate protection regardless of where it is processed.", comment: "International transfers protection"))
                        }
                        .font(.body)
                    }
                    
                    // Policy Changes
                    SectionView(title: LocalizedString("Updates to This Privacy Policy", comment: "Policy changes section")) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(LocalizedString("We may update this Privacy Policy periodically to reflect changes in our practices or for legal, operational, or regulatory reasons.", comment: "Policy changes general"))
                            Text(LocalizedString("When we make material changes, we will notify you by updating the \"Last Updated\" date in the App and, if you have provided an email address, sending you an email notification.", comment: "Policy changes notification"))
                            Text(LocalizedString("Your continued use of the App after changes become effective constitutes acceptance of the updated Privacy Policy. If you do not agree with the changes, you may delete your account.", comment: "Policy changes acceptance"))
                        }
                        .font(.body)
                    }
                    
                    // Contact
                    SectionView(title: LocalizedString("Contact Us", comment: "Contact section")) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(LocalizedString("If you have questions, concerns, or requests about this Privacy Policy or our data practices, please contact us:", comment: "Contact intro"))
                            Text(LocalizedString("Email", comment: "Email label")) + Text(": support@misoto.app")
                            Text(LocalizedString("We will respond to your inquiry as soon as reasonably possible.", comment: "Contact response"))
                            Text(LocalizedString("Last Updated", comment: "Last updated label")) + Text(": " + LocalizedString("January 15, 2026", comment: "Last updated date"))
                        }
                        .font(.body)
                    }
                }
                .padding()
            }
            .navigationTitle(LocalizedString("Privacy Policy", comment: "Privacy policy title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizedString("Done", comment: "Done button")) {
                        HapticFeedback.buttonTap()
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Section View Helper

struct SectionView<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            content
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    PrivacyPolicyView()
}

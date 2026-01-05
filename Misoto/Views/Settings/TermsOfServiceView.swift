//
//  TermsOfServiceView.swift
//  Misoto
//
//  Created by Daniel Chan on 30.12.2025.
//

import SwiftUI

struct TermsOfServiceView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Introduction
                    SectionView(title: LocalizedString("Welcome to Misoto", comment: "Welcome section")) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(LocalizedString("Thank you for using Misoto, a recipe sharing and management platform (the \"App\" or \"Service\"). These Terms of Service (\"Terms\") establish the legal agreement between you (\"User\", \"you\", or \"your\") and Misoto (\"we\", \"us\", \"our\", or \"Misoto\") regarding your use of the App.", comment: "Introduction paragraph 1"))
                            Text(LocalizedString("Please read these Terms carefully. By downloading, installing, accessing, or using the App, you confirm that you have read, understood, and agree to be legally bound by these Terms. If you disagree with any part of these Terms, you must not use the App.", comment: "Introduction paragraph 2"))
                            Text(LocalizedString("These Terms apply to all users of the App, including individuals who create accounts, share recipes, extract content, or otherwise interact with the Service.", comment: "Introduction paragraph 3"))
                        }
                        .font(.body)
                    }
                    
                    // Service Description
                    SectionView(title: LocalizedString("About Misoto", comment: "Service description section")) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(LocalizedString("Misoto is a mobile application that enables users to:", comment: "Service features intro"))
                            VStack(alignment: .leading, spacing: 8) {
                                Text("• " + LocalizedString("Create, organize, and manage personal recipe collections", comment: "Feature 1"))
                                Text("• " + LocalizedString("Extract recipe information from images, websites, and online content using AI technology", comment: "Feature 2"))
                                Text("• " + LocalizedString("Share recipes and culinary discoveries with a community of users", comment: "Feature 3"))
                                Text("• " + LocalizedString("Follow other users and discover new recipes based on interests", comment: "Feature 4"))
                                Text("• " + LocalizedString("Save favorite recipes and add personal notes", comment: "Feature 5"))
                            }
                            .padding(.leading, 16)
                            Text(LocalizedString("The App is designed to help you manage your recipes and connect with others who share your passion for cooking. We continuously work to improve the Service and may add, modify, or remove features from time to time.", comment: "Service description continuation"))
                        }
                        .font(.body)
                    }
                    
                    // User Accounts
                    SectionView(title: LocalizedString("Creating Your Account", comment: "User accounts section")) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(LocalizedString("To access certain features of the App, you need to create an account. When creating an account, you agree to:", comment: "Account creation intro"))
                            VStack(alignment: .leading, spacing: 8) {
                                Text("• " + LocalizedString("Provide accurate, current, and complete information", comment: "Account accuracy"))
                                Text("• " + LocalizedString("Maintain and promptly update your account information", comment: "Account updates"))
                                Text("• " + LocalizedString("Maintain the security of your account credentials", comment: "Account security"))
                                Text("• " + LocalizedString("Accept responsibility for all activities that occur under your account", comment: "Account responsibility"))
                                Text("• " + LocalizedString("Notify us immediately of any unauthorized access or security breach", comment: "Unauthorized access"))
                            }
                            .padding(.leading, 16)
                            Text(LocalizedString("You may create an account using Google Sign-In or Apple Sign-In. You are responsible for maintaining the confidentiality of your account and password. You agree that you will not share your account credentials with anyone else.", comment: "Account authentication"))
                        }
                        .font(.body)
                    }
                    
                    // Acceptable Use
                    SectionView(title: LocalizedString("Using the App Responsibly", comment: "Acceptable use section")) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(LocalizedString("You agree to use the App only for lawful purposes and in accordance with these Terms. You agree not to:", comment: "Acceptable use intro"))
                            VStack(alignment: .leading, spacing: 8) {
                                Text("• " + LocalizedString("Violate any applicable local, state, national, or international law", comment: "Law violation"))
                                Text("• " + LocalizedString("Infringe upon or violate the intellectual property rights, privacy rights, or other rights of others", comment: "Rights violation"))
                                Text("• " + LocalizedString("Post, upload, or share content that is illegal, harmful, threatening, abusive, defamatory, obscene, or otherwise objectionable", comment: "Harmful content"))
                                Text("• " + LocalizedString("Impersonate any person or entity or misrepresent your affiliation with any person or entity", comment: "Impersonation"))
                                Text("• " + LocalizedString("Interfere with or disrupt the App, servers, or networks connected to the App", comment: "Service disruption"))
                                Text("• " + LocalizedString("Use any automated system, including robots, spiders, or scrapers, to access the App without our written permission", comment: "Automated access"))
                                Text("• " + LocalizedString("Attempt to gain unauthorized access to any portion of the App or any systems or networks connected to the App", comment: "Unauthorized access attempt"))
                                Text("• " + LocalizedString("Introduce any viruses, malware, or other harmful code into the App", comment: "Malicious code"))
                            }
                            .padding(.leading, 16)
                        }
                        .font(.body)
                    }
                    
                    // Content Extraction and Third-Party Sources
                    SectionView(title: LocalizedString("Recipe Extraction and Content Sources", comment: "Content extraction section")) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(LocalizedString("Misoto provides features that allow you to extract recipe information from various sources, including:", comment: "Extraction intro"))
                            VStack(alignment: .leading, spacing: 8) {
                                Text("• " + LocalizedString("Photographs of recipe books, magazines, or printed materials", comment: "Photo extraction"))
                                Text("• " + LocalizedString("Images saved on your device", comment: "Image extraction"))
                                Text("• " + LocalizedString("Websites and online recipe pages", comment: "Website extraction"))
                                Text("• " + LocalizedString("Links to online content", comment: "Link extraction"))
                            }
                            .padding(.leading, 16)
                            Text(LocalizedString("Important: You are solely responsible for ensuring that you have the legal right to extract, copy, and use content from these sources. You must comply with all applicable copyright laws, terms of service of the websites you access, and any other legal restrictions.", comment: "Extraction responsibility"))
                                .fontWeight(.medium)
                            Text(LocalizedString("Misoto is a tool that assists with recipe organization and extraction. We do not grant you any rights to use copyrighted material. If you extract recipes from books, websites, or other protected sources, you must ensure you have proper authorization from the copyright holder.", comment: "Extraction disclaimer"))
                                .fontWeight(.medium)
                            Text(LocalizedString("We are not responsible for any copyright infringement, intellectual property violations, or legal issues arising from content you extract or share through the App. Any claims, disputes, or legal actions related to extracted content are solely your responsibility.", comment: "Extraction liability"))
                        }
                        .font(.body)
                    }
                    
                    // User-Generated Content
                    SectionView(title: LocalizedString("Your Content", comment: "User content section")) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(LocalizedString("You retain ownership of the content you create and share through the App, including recipes, notes, images, and other materials (\"Your Content\").", comment: "Content ownership"))
                            Text(LocalizedString("By sharing Your Content on the App, you grant Misoto a worldwide, non-exclusive, royalty-free license to use, display, reproduce, modify, and distribute Your Content solely for the purpose of operating and providing the Service.", comment: "Content license"))
                            Text(LocalizedString("You represent and warrant that:", comment: "Content warranty intro"))
                            VStack(alignment: .leading, spacing: 8) {
                                Text("• " + LocalizedString("You own Your Content or have obtained all necessary rights, licenses, and permissions to use and share it", comment: "Content rights"))
                                Text("• " + LocalizedString("Your Content does not violate any law or infringe upon any rights of any third party", comment: "Content legality"))
                                Text("• " + LocalizedString("Your Content is accurate and not misleading", comment: "Content accuracy"))
                            }
                            .padding(.leading, 16)
                            Text(LocalizedString("We reserve the right, but not the obligation, to review, modify, or remove Your Content at any time if we determine, in our sole discretion, that it violates these Terms or is otherwise inappropriate.", comment: "Content moderation"))
                        }
                        .font(.body)
                    }
                    
                    // Intellectual Property
                    SectionView(title: LocalizedString("Our Rights and Intellectual Property", comment: "IP section")) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(LocalizedString("The App, including its design, features, functionality, code, and all content created by Misoto (excluding user-generated content), is owned by Misoto and protected by copyright, trademark, and other intellectual property laws.", comment: "IP ownership"))
                            Text(LocalizedString("You may not copy, modify, distribute, sell, lease, or create derivative works based on the App or any Misoto-owned content without our express written permission.", comment: "IP restrictions"))
                            Text(LocalizedString("The Misoto name, logo, and related marks are trademarks of Misoto. You may not use these marks without our prior written consent.", comment: "Trademark"))
                            Text(LocalizedString("Subject to your compliance with these Terms, we grant you a limited, non-exclusive, non-transferable, revocable license to access and use the App for your personal, non-commercial use on devices you own or control.", comment: "App license"))
                        }
                        .font(.body)
                    }
                    
                    // Third-Party Services
                    SectionView(title: LocalizedString("Third-Party Services and Technologies", comment: "Third-party section")) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(LocalizedString("The App integrates with third-party services and technologies to provide certain features:", comment: "Third-party intro"))
                            VStack(alignment: .leading, spacing: 8) {
                                Text("• " + LocalizedString("Firebase (Google) - For user authentication, data storage, and file hosting", comment: "Firebase service"))
                                Text("• " + LocalizedString("OpenAI - For AI-powered recipe extraction and content processing", comment: "OpenAI service"))
                            }
                            .padding(.leading, 16)
                            Text(LocalizedString("These services are subject to their own terms of service and privacy policies. Your use of these services is also governed by their respective terms. We are not responsible for the practices, policies, or content of these third-party services.", comment: "Third-party terms"))
                            Text(LocalizedString("The information and content provided through third-party services are for general information purposes only. We make no representations or warranties about the accuracy, completeness, or usefulness of such information.", comment: "Third-party disclaimer"))
                        }
                        .font(.body)
                    }
                    
                    // Privacy and Data
                    SectionView(title: LocalizedString("Privacy and Data Protection", comment: "Privacy section")) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(LocalizedString("Your privacy is important to us. Our collection and use of your information is described in our Privacy Policy, which is incorporated into these Terms by reference. By using the App, you consent to our privacy practices as described in the Privacy Policy.", comment: "Privacy reference"))
                            Text(LocalizedString("You can manage your privacy settings within the App, including controlling who can see your profile and recipes. Please review the Privacy Policy to understand your rights and choices regarding your personal information.", comment: "Privacy settings"))
                        }
                        .font(.body)
                    }
                    
                    // Account Termination
                    SectionView(title: LocalizedString("Account Termination", comment: "Termination section")) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(LocalizedString("You may terminate your account at any time by using the account deletion feature in the App's settings. When you delete your account, we will remove your account information, recipes, notes, and associated data from our systems.", comment: "User termination"))
                            Text(LocalizedString("We reserve the right to suspend or terminate your account, with or without notice, if you violate these Terms, engage in fraudulent or illegal activity, or for any other reason we deem necessary to protect the integrity of the Service or our users.", comment: "Company termination"))
                            Text(LocalizedString("Upon termination, your right to use the App will immediately cease. All provisions of these Terms that by their nature should survive termination will survive, including ownership provisions, warranty disclaimers, and limitations of liability.", comment: "Termination effects"))
                        }
                        .font(.body)
                    }
                    
                    // Disclaimers
                    SectionView(title: LocalizedString("Service Availability and Disclaimers", comment: "Disclaimers section")) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(LocalizedString("The App is provided \"as is\" and \"as available\" without warranties of any kind, either express or implied. To the fullest extent permitted by law, we disclaim all warranties, including but not limited to implied warranties of merchantability, fitness for a particular purpose, and non-infringement.", comment: "Warranty disclaimer"))
                            Text(LocalizedString("We do not warrant that the App will be uninterrupted, error-free, secure, or free from viruses or other harmful components. We do not guarantee the accuracy, completeness, or usefulness of any information provided through the App.", comment: "Service warranty disclaimer"))
                            Text(LocalizedString("Recipe information, cooking instructions, and nutritional data are provided for informational purposes only. You are responsible for verifying the accuracy of recipe information and using your own judgment when preparing recipes. We are not responsible for any adverse effects, injuries, or damages resulting from the use of recipes or information obtained through the App.", comment: "Recipe disclaimer"))
                        }
                        .font(.body)
                    }
                    
                    // Limitation of Liability
                    SectionView(title: LocalizedString("Limitation of Liability", comment: "Liability section")) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(LocalizedString("To the maximum extent permitted by applicable law, in no event shall Misoto, its affiliates, or their respective officers, directors, employees, or agents be liable for any indirect, incidental, special, consequential, or punitive damages, including but not limited to loss of profits, data, use, goodwill, or other intangible losses, resulting from your use of or inability to use the App.", comment: "Liability limitation"))
                            Text(LocalizedString("Our total liability to you for all claims arising out of or relating to your use of the App shall not exceed the amount you paid to us, if any, in the 12 months preceding the claim, or one hundred dollars ($100), whichever is greater.", comment: "Liability cap"))
                            Text(LocalizedString("Some jurisdictions do not allow the exclusion or limitation of certain damages, so some of the above limitations may not apply to you.", comment: "Jurisdiction note"))
                        }
                        .font(.body)
                    }
                    
                    // Indemnification
                    SectionView(title: LocalizedString("Your Indemnification Obligations", comment: "Indemnification section")) {
                        Text(LocalizedString("You agree to defend, indemnify, and hold harmless Misoto, its affiliates, and their respective officers, directors, employees, and agents from and against any claims, liabilities, damages, losses, and expenses, including reasonable attorney's fees, arising out of or relating to your use of the App, Your Content, your violation of these Terms, or your violation of any rights of another party.", comment: "Indemnification text"))
                            .font(.body)
                    }
                    
                    // Modifications to Terms
                    SectionView(title: LocalizedString("Changes to These Terms", comment: "Terms changes section")) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(LocalizedString("We may update these Terms from time to time to reflect changes in our practices, the App, or for legal, operational, or regulatory reasons. We will notify you of any material changes by posting the updated Terms in the App and updating the \"Last Updated\" date.", comment: "Terms changes policy"))
                            Text(LocalizedString("Your continued use of the App after any changes to these Terms constitutes your acceptance of the updated Terms. If you do not agree to the updated Terms, you must stop using the App and delete your account.", comment: "Terms changes acceptance"))
                        }
                        .font(.body)
                    }
                    
                    // Governing Law
                    SectionView(title: LocalizedString("Governing Law and Disputes", comment: "Governing law section")) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(LocalizedString("These Terms shall be governed by and construed in accordance with the laws of the jurisdiction where Misoto operates, without regard to its conflict of law provisions.", comment: "Governing law"))
                            Text(LocalizedString("Any disputes arising out of or relating to these Terms or your use of the App shall be resolved through binding arbitration or in the courts of the jurisdiction where Misoto operates, as determined by applicable law.", comment: "Dispute resolution"))
                        }
                        .font(.body)
                    }
                    
                    // Severability
                    SectionView(title: LocalizedString("General Provisions", comment: "General provisions section")) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(LocalizedString("If any provision of these Terms is found to be unenforceable or invalid, that provision shall be limited or eliminated to the minimum extent necessary, and the remaining provisions shall remain in full force and effect.", comment: "Severability"))
                            Text(LocalizedString("These Terms, together with our Privacy Policy, constitute the entire agreement between you and Misoto regarding your use of the App and supersede all prior agreements and understandings.", comment: "Entire agreement"))
                            Text(LocalizedString("Our failure to enforce any right or provision of these Terms shall not constitute a waiver of such right or provision. We may assign these Terms or any rights hereunder without your consent.", comment: "Waiver and assignment"))
                        }
                        .font(.body)
                    }
                    
                    // Contact
                    SectionView(title: LocalizedString("Questions or Concerns", comment: "Contact section")) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(LocalizedString("If you have any questions about these Terms, please contact us:", comment: "Contact intro"))
                            Text(LocalizedString("Email", comment: "Email label")) + Text(": support@misoto.app")
                            Text(LocalizedString("We will make our best effort to respond to your inquiries in a timely manner.", comment: "Contact response"))
                            Text(LocalizedString("Last Updated", comment: "Last updated label")) + Text(": " + LocalizedString("December 30, 2025", comment: "Last updated date"))
                        }
                        .font(.body)
                    }
                }
                .padding()
            }
            .navigationTitle(LocalizedString("Terms of Service", comment: "Terms of service title"))
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

#Preview {
    TermsOfServiceView()
}

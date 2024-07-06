//
//  GoogleAIView.swift
//  StikApp
//
//  Created by Blu on 7/6/24.
//

import SwiftUI
import GoogleGenerativeAI

struct GoogleAIView: View {
    @State private var prompt = ""
    @State private var messages: [Message] = []
    @State private var isLoading = false
    @State private var errorMessage = ""

    var body: some View {
        VStack {
            Spacer().frame(height: 100)

            if messages.isEmpty {
                Spacer()
                Text("No messages yet")
                    .foregroundColor(.gray)
                Spacer()
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(messages) { message in
                            HStack {
                                if message.isUser {
                                    Spacer()
                                    MessageBubble(text: message.text, isUser: message.isUser)
                                        .padding(.leading, 50)
                                } else {
                                    MessageBubble(text: message.text, isUser: message.isUser)
                                        .padding(.trailing, 50)
                                    Spacer()
                                }
                            }
                        }
                    }
                    .padding()
                }
                .background(Color(UIColor.systemGroupedBackground))
                .cornerRadius(10)
                .padding()
            }

            HStack {
                TextField("Enter your prompt", text: $prompt)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 5)
                    .disableAutocorrection(true)

                Button(action: {
                    Task {
                        await generateResponse()
                    }
                }) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.white)
                        .padding()
                        .background(prompt.isEmpty ? Color.gray : Color.blue)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 5)
                }
                .disabled(prompt.isEmpty || isLoading)
            }
            .padding()
        }
        .background(Color(UIColor.systemBackground))
        .edgesIgnoringSafeArea(.all)
    }

    func generateResponse() async {
        guard !prompt.isEmpty else { return }

        isLoading = true
        errorMessage = ""

        let userMessage = Message(id: UUID(), text: prompt, isUser: true)
        messages.append(userMessage)
        prompt = ""

        let apiKey = Bundle.main.object(forInfoDictionaryKey: "API_KEY") as? String
        guard let apiKey = apiKey else {
            errorMessage = "Error: API Key not found"
            isLoading = false
            return
        }

        let model = GenerativeModel(name: "gemini-1.5-flash-latest", apiKey: apiKey)
        do {
            let response = try await model.generateContent(userMessage.text)
            if let unwrappedText = response.text {
                let aiMessage = Message(id: UUID(), text: unwrappedText, isUser: false)
                messages.append(aiMessage)
            } else {
                errorMessage = "Error: Could not get text response"
            }
        } catch {
            errorMessage = "Error generating response: \(error)"
        }

        isLoading = false
    }
}

struct Message: Identifiable {
    let id: UUID
    let text: String
    let isUser: Bool
}

struct MessageBubble: View {
    let text: String
    let isUser: Bool

    var body: some View {
        Text(text)
            .padding()
            .background(isUser ? Color.blue : Color(UIColor.systemGray5))
            .foregroundColor(isUser ? .white : .black)
            .cornerRadius(15)
            .shadow(radius: 1)
            .frame(maxWidth: 250, alignment: isUser ? .trailing : .leading)
            .padding(isUser ? .trailing : .leading, 10)
    }
}

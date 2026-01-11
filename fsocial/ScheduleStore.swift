//
//  ScheduleStore.swift
//  fsocial
//
//  Created by Mason Earl on 1/11/26.
//

import Foundation
import SwiftUI
import UserNotifications
import Combine

class ScheduleStore: ObservableObject {
    private let storageKey = "com.fsocial.scheduledposts"
    
    @Published var posts: [ScheduledPost] = []
    
    init() {
        loadPosts()
        requestNotificationPermission()
    }
    
    private func loadPosts() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let savedPosts = try? JSONDecoder().decode([ScheduledPost].self, from: data) {
            posts = savedPosts
        }
    }
    
    private func savePosts() {
        if let data = try? JSONEncoder().encode(posts) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
    
    // MARK: - Filtering
    
    var upcomingPosts: [ScheduledPost] {
        posts.filter { !$0.isPosted && !$0.isPast }
            .sorted { $0.scheduledDate < $1.scheduledDate }
    }
    
    var todaysPosts: [ScheduledPost] {
        posts.filter { $0.isToday && !$0.isPosted }
            .sorted { $0.scheduledDate < $1.scheduledDate }
    }
    
    var pastPosts: [ScheduledPost] {
        posts.filter { $0.isPast || $0.isPosted }
            .sorted { $0.scheduledDate > $1.scheduledDate }
    }
    
    func posts(for date: Date) -> [ScheduledPost] {
        posts.filter { Calendar.current.isDate($0.scheduledDate, inSameDayAs: date) }
            .sorted { $0.scheduledDate < $1.scheduledDate }
    }
    
    // MARK: - CRUD Operations
    
    func addPost(content: String, platforms: [Platform], scheduledDate: Date, notes: String = "") {
        let post = ScheduledPost(
            content: content,
            platforms: platforms,
            scheduledDate: scheduledDate,
            notes: notes
        )
        posts.append(post)
        savePosts()
        scheduleNotification(for: post)
    }
    
    func updatePost(_ post: ScheduledPost, content: String, platforms: [Platform], scheduledDate: Date, notes: String) {
        if let index = posts.firstIndex(where: { $0.id == post.id }) {
            cancelNotification(for: posts[index])
            posts[index].content = content
            posts[index].platforms = platforms
            posts[index].scheduledDate = scheduledDate
            posts[index].notes = notes
            savePosts()
            scheduleNotification(for: posts[index])
        }
    }
    
    func markAsPosted(_ post: ScheduledPost) {
        if let index = posts.firstIndex(where: { $0.id == post.id }) {
            posts[index].isPosted = true
            savePosts()
            cancelNotification(for: post)
        }
    }
    
    func deletePost(_ post: ScheduledPost) {
        cancelNotification(for: post)
        posts.removeAll { $0.id == post.id }
        savePosts()
    }
    
    // MARK: - Notifications
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }
    
    private func scheduleNotification(for post: ScheduledPost) {
        let content = UNMutableNotificationContent()
        content.title = "Time to post!"
        content.body = String(post.content.prefix(100)) + (post.content.count > 100 ? "..." : "")
        content.sound = .default
        
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: post.scheduledDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(identifier: post.id.uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error)")
            }
        }
    }
    
    private func cancelNotification(for post: ScheduledPost) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [post.id.uuidString])
    }
    
    // MARK: - Calendar Helpers
    
    func hasPostsOnDate(_ date: Date) -> Bool {
        posts.contains { Calendar.current.isDate($0.scheduledDate, inSameDayAs: date) }
    }
    
    var datesWithPosts: Set<DateComponents> {
        Set(posts.map { Calendar.current.dateComponents([.year, .month, .day], from: $0.scheduledDate) })
    }
}

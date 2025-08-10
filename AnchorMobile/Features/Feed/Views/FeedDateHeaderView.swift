import SwiftUI

struct FeedDateHeaderView: View {
    let date: Date
    
    var body: some View {
        HStack {
            Text(formattedDate)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(UIColor.systemGroupedBackground))
    }
    
    private var formattedDate: String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else if calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear) {
            // This week - show day name
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter.string(from: date)
        } else if calendar.isDate(date, equalTo: now, toGranularity: .year) {
            // This year - show month and day
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM d"
            return formatter.string(from: date)
        } else {
            // Other years - show full date
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
    }
}

#Preview {
    VStack(spacing: 0) {
        FeedDateHeaderView(date: Date())
        FeedDateHeaderView(date: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date())
        FeedDateHeaderView(date: Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date())
        FeedDateHeaderView(date: Calendar.current.date(byAdding: .month, value: -2, to: Date()) ?? Date())
        FeedDateHeaderView(date: Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date())
    }
}

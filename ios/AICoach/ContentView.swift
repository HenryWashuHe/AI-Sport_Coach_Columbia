import SwiftUI

struct ContentView: View {
    var body: some View {
        HomeView()
    }
}

struct HomeView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Text("AI Coach")
                    .font(.largeTitle.bold())
                    .foregroundColor(.blue)
                
                Text("Your Personal Training Assistant")
                    .font(.title2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Spacer()
                
                NavigationLink(destination: SimpleWorkoutView()) {
                    Text("Start Workout")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                        .frame(width: 200, height: 50)
                        .background(Color.blue)
                        .cornerRadius(25)
                }
                
                NavigationLink(destination: PreviewWorkoutView()) {
                    Text("Preview UI")
                        .font(.title2)
                        .foregroundColor(.blue)
                        .frame(width: 200, height: 50)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(25)
                }
                
                Spacer()
            }
            .padding()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

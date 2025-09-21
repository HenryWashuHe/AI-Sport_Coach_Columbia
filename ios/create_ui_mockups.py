#!/usr/bin/env python3
"""
Create UI mockups for AI Coach app
Shows what the app will look like before building
"""

import matplotlib.pyplot as plt
import matplotlib.patches as patches
from matplotlib.patches import Circle, Rectangle, FancyBboxPatch
import numpy as np

def create_workout_screen_mockup():
    """Create a mockup of the main workout screen"""
    
    fig, ax = plt.subplots(1, 1, figsize=(6, 12))
    ax.set_xlim(0, 375)  # iPhone width
    ax.set_ylim(0, 812)  # iPhone height
    ax.set_aspect('equal')
    ax.axis('off')
    
    # Background (camera view)
    camera_bg = Rectangle((0, 0), 375, 812, facecolor='#1a1a2e', alpha=0.9)
    ax.add_patch(camera_bg)
    
    # Top status bar
    status_bar = FancyBboxPatch((20, 750), 335, 50, 
                               boxstyle="round,pad=10", 
                               facecolor='black', alpha=0.7,
                               edgecolor='white', linewidth=1)
    ax.add_patch(status_bar)
    
    # Heart rate display
    ax.text(40, 775, "❤️ 142", fontsize=16, color='red', weight='bold')
    ax.text(40, 760, "BPM", fontsize=10, color='white', alpha=0.8)
    
    # Timer
    ax.text(140, 775, "⏱️ 05:23", fontsize=16, color='green', weight='bold')
    
    # Reps counter
    ax.text(280, 775, "Reps: 8", fontsize=16, color='white', weight='bold')
    ax.text(280, 760, "Depth: 78%", fontsize=12, color='green')
    
    # Mock pose skeleton
    # Head
    head = Circle((187, 600), 15, facecolor='yellow', edgecolor='green', linewidth=2)
    ax.add_patch(head)
    
    # Body joints
    joints = [
        (170, 550),  # Left shoulder
        (204, 550),  # Right shoulder
        (150, 500),  # Left elbow
        (224, 500),  # Right elbow
        (130, 450),  # Left wrist
        (244, 450),  # Right wrist
        (175, 450),  # Left hip
        (199, 450),  # Right hip
        (170, 350),  # Left knee
        (204, 350),  # Right knee
        (165, 250),  # Left ankle
        (209, 250),  # Right ankle
    ]
    
    for joint in joints:
        circle = Circle(joint, 6, facecolor='lime', edgecolor='green', linewidth=2)
        ax.add_patch(circle)
    
    # Skeleton connections
    connections = [
        [(170, 550), (204, 550)],  # Shoulders
        [(170, 550), (175, 450)],  # Left torso
        [(204, 550), (199, 450)],  # Right torso
        [(175, 450), (199, 450)],  # Hips
        [(170, 550), (150, 500)],  # Left upper arm
        [(150, 500), (130, 450)],  # Left forearm
        [(204, 550), (224, 500)],  # Right upper arm
        [(224, 500), (244, 450)],  # Right forearm
        [(175, 450), (170, 350)],  # Left thigh
        [(170, 350), (165, 250)],  # Left shin
        [(199, 450), (204, 350)],  # Right thigh
        [(204, 350), (209, 250)],  # Right shin
    ]
    
    for connection in connections:
        ax.plot([connection[0][0], connection[1][0]], 
               [connection[0][1], connection[1][1]], 
               'g-', linewidth=3, alpha=0.8)
    
    # Coaching cue bubble
    cue_box = FancyBboxPatch((50, 400), 275, 60, 
                            boxstyle="round,pad=15", 
                            facecolor='black', alpha=0.8,
                            edgecolor='lime', linewidth=2)
    ax.add_patch(cue_box)
    ax.text(187, 430, "Great form!", fontsize=18, color='white', 
           weight='bold', ha='center', va='center')
    
    # Bottom control panel
    control_panel = FancyBboxPatch((20, 50), 335, 100, 
                                  boxstyle="round,pad=15", 
                                  facecolor='black', alpha=0.7,
                                  edgecolor='white', linewidth=1)
    ax.add_patch(control_panel)
    
    # Tempo display
    ax.text(60, 120, "TEMPO", fontsize=10, color='white', alpha=0.7, ha='center')
    ax.text(60, 100, "1.4s", fontsize=16, color='orange', weight='bold', ha='center')
    
    # End workout button
    end_button = FancyBboxPatch((140, 80), 95, 40, 
                               boxstyle="round,pad=8", 
                               facecolor='red', alpha=0.9)
    ax.add_patch(end_button)
    ax.text(187, 100, "End Workout", fontsize=12, color='white', 
           weight='bold', ha='center', va='center')
    
    # Settings
    ax.text(315, 120, "⚙️", fontsize=20, ha='center')
    ax.text(315, 100, "Settings", fontsize=10, color='white', alpha=0.7, ha='center')
    
    plt.title("AI Coach - Workout Screen", fontsize=16, color='white', pad=20)
    plt.tight_layout()
    return fig

def create_summary_screen_mockup():
    """Create a mockup of the workout summary screen"""
    
    fig, ax = plt.subplots(1, 1, figsize=(6, 12))
    ax.set_xlim(0, 375)
    ax.set_ylim(0, 812)
    ax.set_aspect('equal')
    ax.axis('off')
    
    # Background
    bg = Rectangle((0, 0), 375, 812, facecolor='#f8f9fa')
    ax.add_patch(bg)
    
    # Header
    header = Rectangle((0, 750), 375, 62, facecolor='#4facfe')
    ax.add_patch(header)
    ax.text(187, 781, "Workout Complete! 🎉", fontsize=18, color='white', 
           weight='bold', ha='center', va='center')
    
    # Stats cards
    cards = [
        {"title": "Duration", "value": "5:23", "icon": "⏱️", "y": 650},
        {"title": "Reps", "value": "12", "icon": "🏋️", "y": 550},
        {"title": "Avg Heart Rate", "value": "142 BPM", "icon": "❤️", "y": 450},
        {"title": "Form Score", "value": "85%", "icon": "⭐", "y": 350},
    ]
    
    for card in cards:
        # Card background
        card_bg = FancyBboxPatch((30, card["y"]), 315, 80, 
                                boxstyle="round,pad=15", 
                                facecolor='white', 
                                edgecolor='#e9ecef', linewidth=1)
        ax.add_patch(card_bg)
        
        # Icon
        ax.text(60, card["y"] + 50, card["icon"], fontsize=24, ha='center', va='center')
        
        # Title and value
        ax.text(100, card["y"] + 60, card["title"], fontsize=14, color='#6c757d', weight='bold')
        ax.text(100, card["y"] + 35, card["value"], fontsize=20, color='#212529', weight='bold')
    
    # Form feedback section
    feedback_bg = FancyBboxPatch((30, 200), 315, 120, 
                                boxstyle="round,pad=15", 
                                facecolor='#d4edda', 
                                edgecolor='#c3e6cb', linewidth=1)
    ax.add_patch(feedback_bg)
    
    ax.text(187, 290, "Form Feedback", fontsize=16, color='#155724', 
           weight='bold', ha='center')
    ax.text(50, 260, "✅ Great squat depth", fontsize=12, color='#155724')
    ax.text(50, 240, "✅ Good tempo control", fontsize=12, color='#155724')
    ax.text(50, 220, "⚠️ Watch knee alignment", fontsize=12, color='#856404')
    
    # Action buttons
    share_btn = FancyBboxPatch((30, 100), 150, 50, 
                              boxstyle="round,pad=10", 
                              facecolor='#007bff')
    ax.add_patch(share_btn)
    ax.text(105, 125, "Share Results", fontsize=14, color='white', 
           weight='bold', ha='center', va='center')
    
    done_btn = FancyBboxPatch((195, 100), 150, 50, 
                             boxstyle="round,pad=10", 
                             facecolor='#28a745')
    ax.add_patch(done_btn)
    ax.text(270, 125, "Done", fontsize=14, color='white', 
           weight='bold', ha='center', va='center')
    
    plt.title("AI Coach - Workout Summary", fontsize=16, color='#212529', pad=20)
    plt.tight_layout()
    return fig

def create_home_screen_mockup():
    """Create a mockup of the home screen"""
    
    fig, ax = plt.subplots(1, 1, figsize=(6, 12))
    ax.set_xlim(0, 375)
    ax.set_ylim(0, 812)
    ax.set_aspect('equal')
    ax.axis('off')
    
    # Background gradient
    bg = Rectangle((0, 0), 375, 812, facecolor='#667eea')
    ax.add_patch(bg)
    
    # App title
    ax.text(187, 720, "AI Coach", fontsize=32, color='white', 
           weight='bold', ha='center', va='center')
    ax.text(187, 690, "Your Personal Training Assistant", fontsize=14, 
           color='white', alpha=0.9, ha='center', va='center')
    
    # Main illustration (simplified)
    # Person silhouette
    person = FancyBboxPatch((150, 450), 75, 150, 
                           boxstyle="round,pad=5", 
                           facecolor='white', alpha=0.3)
    ax.add_patch(person)
    
    # AI elements around person
    ai_elements = [
        {"pos": (100, 550), "text": "❤️", "label": "HR Monitor"},
        {"pos": (275, 550), "text": "📊", "label": "Form Analysis"},
        {"pos": (100, 450), "text": "🗣️", "label": "Voice Coaching"},
        {"pos": (275, 450), "text": "📱", "label": "Real-time"},
    ]
    
    for element in ai_elements:
        # Icon circle
        circle = Circle(element["pos"], 20, facecolor='white', alpha=0.8)
        ax.add_patch(circle)
        ax.text(element["pos"][0], element["pos"][1], element["text"], 
               fontsize=16, ha='center', va='center')
        
        # Label
        ax.text(element["pos"][0], element["pos"][1] - 40, element["label"], 
               fontsize=10, color='white', ha='center', va='center')
    
    # Start workout button
    start_btn = FancyBboxPatch((87, 300), 200, 60, 
                              boxstyle="round,pad=15", 
                              facecolor='#00f2fe', 
                              edgecolor='white', linewidth=2)
    ax.add_patch(start_btn)
    ax.text(187, 330, "Start Workout", fontsize=18, color='white', 
           weight='bold', ha='center', va='center')
    
    # Feature highlights
    features = [
        "✅ Real-time pose analysis",
        "✅ Live heart rate monitoring", 
        "✅ Intelligent form correction",
        "✅ Privacy-first design"
    ]
    
    for i, feature in enumerate(features):
        ax.text(50, 220 - i*30, feature, fontsize=12, color='white', 
               alpha=0.9, va='center')
    
    # Bottom navigation hint
    ax.text(187, 50, "Swipe up to begin your workout", fontsize=12, 
           color='white', alpha=0.7, ha='center', va='center', style='italic')
    
    plt.title("AI Coach - Home Screen", fontsize=16, color='white', pad=20)
    plt.tight_layout()
    return fig

def main():
    """Generate all UI mockups"""
    print("🎨 Generating AI Coach UI Mockups...")
    
    # Create mockups
    home_fig = create_home_screen_mockup()
    workout_fig = create_workout_screen_mockup()
    summary_fig = create_summary_screen_mockup()
    
    # Save mockups
    home_fig.savefig('/Users/heshi/Downloads/ai-coach/ios/mockup_home_screen.png', 
                     dpi=150, bbox_inches='tight', facecolor='#667eea')
    
    workout_fig.savefig('/Users/heshi/Downloads/ai-coach/ios/mockup_workout_screen.png', 
                        dpi=150, bbox_inches='tight', facecolor='#1a1a2e')
    
    summary_fig.savefig('/Users/heshi/Downloads/ai-coach/ios/mockup_summary_screen.png', 
                        dpi=150, bbox_inches='tight', facecolor='#f8f9fa')
    
    print("✅ UI Mockups saved:")
    print("   📱 Home Screen: ios/mockup_home_screen.png")
    print("   🏋️ Workout Screen: ios/mockup_workout_screen.png")
    print("   📊 Summary Screen: ios/mockup_summary_screen.png")
    
    # Show mockups
    plt.show()

if __name__ == "__main__":
    main()

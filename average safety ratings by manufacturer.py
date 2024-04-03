# Data
manufacturers = ['Chevrolet', 'Hyundai', 'Tesla', 'BMW', 'Nissan', 'Honda', 'Ford', 'Volkswagen', 'Toyota']
average_safety_ratings = [4.766666666666667, 4.733333333333333, 4.7, 4.666666666666667, 4.666666666666666, 
                          4.566666666666666, 4.525, 4.475, 4.425]

# Plotting
plt.figure(figsize=(12, 8))
bars = plt.bar(manufacturers, average_safety_ratings, color='skyblue')
plt.title('Average Safety Rating by Manufacturer')
plt.xlabel('Manufacturer')
plt.ylabel('Average Safety Rating')
plt.xticks(rotation=45, ha='right')
plt.grid(axis='y')

# Adding the value on top of each bar
for bar in bars:
    yval = bar.get_height()
    plt.text(bar.get_x() + bar.get_width()/2.0, yval, round(yval, 2), va='bottom')  # va: vertical alignment

plt.tight_layout()
plt.show()

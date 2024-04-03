# Adjusting the y-axis to make differences more noticeable
plt.figure(figsize=(12, 8))
bars = plt.bar(manufacturers, average_safety_ratings, color='skyblue')
plt.title('Average Safety Rating by Manufacturer (Adjusted Scale)')
plt.xlabel('Manufacturer')
plt.ylabel('Average Safety Rating')
plt.xticks(rotation=45, ha='right')
plt.grid(axis='y')

# Set y-axis to start from the minimum rating minus a small value to make the differences more noticeable
plt.ylim(min(average_safety_ratings) - 0.1, max(average_safety_ratings) + 0.1)

# Adding the value on top of each bar
for bar in bars:
    yval = bar.get_height()
    plt.text(bar.get_x() + bar.get_width()/2.0, yval, round(yval, 2), va='bottom')  # va: vertical alignment

plt.tight_layout()
plt.show()

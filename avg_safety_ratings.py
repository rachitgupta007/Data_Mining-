import matplotlib.pyplot as plt

# Data
years = [2018, 2019, 2020, 2021, 2022, 2023]
avg_safety_ratings = [3.75, 4.05, 4.35, 4.55, 4.663636363636364, 4.845454545454545]

# Plotting
plt.figure(figsize=(10, 6))
plt.plot(years, avg_safety_ratings, marker='o', linestyle='-', color='b')
plt.title('Average Safety Rating by Release Year')
plt.xlabel('Release Year')
plt.ylabel('Average Safety Rating')
plt.grid(True)
plt.xticks(years)
plt.tight_layout()

plt.show()

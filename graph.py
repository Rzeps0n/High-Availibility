#!/usr/bin/env python3
import numpy as np
import matplotlib.pyplot as plt

# -----------------------
# Raw data (copied from your table)
# Each entry = list of 10 measurements
# -----------------------

vm_counts = [3, 6, 9, 12, 15]

# OpenTofu create times
opentofu_create = {
3:  [4.212, 4.01, 3.969, 5.028, 4.993, 4.871, 3.893, 4.917, 3.903, 3.907],
6:  [5.23, 5.007, 5.011, 5.028, 5.039, 5.013, 4.983, 4.989, 4.988, 4.999],
9:  [6.287, 6.099, 6.074, 6.057, 6.051, 6.077, 6.068, 6.101, 6.08, 6.139],
12:  [9.477, 9.399, 9.489, 9.393, 9.47, 9.672, 9.516, 9.528, 9.396, 9.419],
15:  [10.69, 10.492, 10.377, 10.487, 10.487, 13.567, 11.477, 10.522, 10.516, 10.549],
}

# OpenTofu destroy times
opentofu_destroy = {
3:  [24.699, 24.651, 25.735, 24.711, 24.661, 23.382, 25.638, 24.666, 25.628, 24.711],
6:  [25.754, 25.814, 26.762, 25.742, 26.846, 25.806, 25.75, 25.745, 26.778, 25.725],
9:  [26.96, 26.905, 26.999, 25.961, 26.927, 26.974, 27.035, 26.072, 25.953, 25.966],
12:  [28.92, 27.809, 30.86, 28.651, 30.006, 29.982, 28.529, 28.456, 27.93, 28.041],
15:  [29.209, 30.559, 29.055, 30.123, 29.938, 29.017, 29.075, 30.116, 29.567, 29.864],
}

# Ansible create times
ansible_create = {
3:  [9.17, 8.244, 8.135, 8.139, 8.245, 8.162, 8.074, 8.36, 8.253, 11.903],
6:  [14.624, 13.905, 13.918, 13.915, 13.828, 13.88, 13.977, 13.992, 13.894, 17.575],
9:  [23.989, 19.751, 19.774, 19.732, 19.635, 19.689, 19.595, 19.706, 19.671, 19.87],
12:  [26.573, 25.508, 29.097, 25.57, 25.389, 25.507, 25.523, 25.75, 25.528, 25.583],
15:  [32.242, 31.646, 34.934, 31.419, 31.248, 31.43, 31.745, 31.678, 31.343, 31.571],
}

# Ansible destroy times
ansible_destroy = {
3:  [7.3, 8.392, 6.549, 7.372, 9.406, 6.283, 6.527, 7.604, 6.615, 9.36],
6:  [11.774, 10.925, 10.823, 10.735, 12.057, 11.035, 15.405, 12.817, 13.09, 12.818],
9:  [17.281, 16.983, 17.644, 16.499, 18.502, 18.503, 15.531, 16.636, 18.478, 17.672],
12:  [20.019, 23.246, 23.082, 21.362, 20.039, 20.632, 19.796, 21.005, 21.098, 22.283],
15:  [27.79, 25.685, 25.977, 26.95, 26.244, 30.012, 26.624, 30.012, 26.31, 26.671],
}

def add_trendline(x, y, label, linestyle='--'):
    coeffs = np.polyfit(x, y, 1)   # 1 = linear, 2 = quadratic, etc.
    poly = np.poly1d(coeffs)

    x_smooth = np.linspace(min(x), max(x), 100)
    plt.plot(x_smooth, poly(x_smooth), linestyle, label=f"{label} Trend")

def compute_avg_std(data_dict):
    """Return lists of averages and standard deviations ordered by vm_counts."""
    avgs = []
    stds = []
    for vm in vm_counts:
        values = np.array(data_dict[vm])
        avgs.append(values.mean())
        stds.append(values.std(ddof=1))  # sample standard deviation
    return avgs, stds


# Calculate stats
ot_create_avg, ot_create_std = compute_avg_std(opentofu_create)
ot_destroy_avg, ot_destroy_std = compute_avg_std(opentofu_destroy)

an_create_avg, an_create_std = compute_avg_std(ansible_create)
an_destroy_avg, an_destroy_std = compute_avg_std(ansible_destroy)


# -----------------------
# Plot 1: Create times
# -----------------------
plt.figure(figsize=(8, 5))
plt.errorbar(vm_counts, ot_create_avg, yerr=ot_create_std, fmt='o-', capsize=5, label="OpenTofu")
plt.errorbar(vm_counts, an_create_avg, yerr=an_create_std, fmt='s-', capsize=5, label="Ansible")

add_trendline(vm_counts, ot_create_avg, "OpenTofu")
add_trendline(vm_counts, an_create_avg, "Ansible")

plt.xlabel("VM count")
plt.ylabel("Average creation time [s]")
plt.title("Average VM Creation Time vs VM Count (10 iterations, SD)")
plt.legend()
plt.grid(True)
plt.tight_layout()
plt.show()


# -----------------------
# Plot 2: Destroy times
# -----------------------
plt.figure(figsize=(8, 5))
plt.errorbar(vm_counts, ot_destroy_avg, yerr=ot_destroy_std, fmt='o-', capsize=5, label="OpenTofu")
plt.errorbar(vm_counts, an_destroy_avg, yerr=an_destroy_std, fmt='s-', capsize=5, label="Ansible")

add_trendline(vm_counts, ot_destroy_avg, "OpenTofu")
add_trendline(vm_counts, an_destroy_avg, "Ansible")

plt.xlabel("VM count")
plt.ylabel("Average destruction time [s]")
plt.title("Average VM Destruction Time vs VM Count (10 iterations, SD)")
plt.legend()
plt.grid(True)
plt.tight_layout()
plt.show()

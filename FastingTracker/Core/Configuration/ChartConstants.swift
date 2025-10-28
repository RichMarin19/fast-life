import Foundation

/// Chart Display Constants
/// Centralizes all chart-related magic numbers for weight tracking visualizations
/// Following industry best practice: Single source of truth for UI configuration
///
/// Reference: Phase 8.9 Weight Tracker Refactoring (Issues #9-13)
/// Updated: October 28, 2025

// MARK: - Chart Constants

enum ChartConstants {

    // MARK: - Y-Axis Padding

    /// Padding values for chart Y-axis (weight axis) based on time range
    /// Used in: WeightChartViewModel Y-axis calculations
    /// Rationale: Different time ranges need different vertical spacing for optimal visualization
    enum YAxisPadding {
        /// Day view padding (5.0 lbs)
        /// Short time range shows minimal weight change, needs more padding for readability
        static let day: Double = 5.0

        /// Week view padding (2.5 lbs)
        /// Moderate time range, balanced padding
        static let week: Double = 2.5

        /// Month view padding (15% of data range)
        /// Longer time range, padding scales with data variability
        static let month: Double = 0.15

        /// Three months view padding (20% of data range)
        /// Extended time range, slightly more padding for trend visibility
        static let threeMonths: Double = 0.20

        /// Year view padding (25% of data range)
        /// Long time range, generous padding to show overall trend
        static let year: Double = 0.25

        /// All-time view padding (30% of data range)
        /// Maximum time range, maximum padding for complete picture
        static let all: Double = 0.30

        /// Minimum padding when data range is small (10% of data range)
        /// Prevents charts from appearing too "zoomed in" with minimal variation
        static let minimumPercentage: Double = 0.10
    }

    // MARK: - X-Axis Configuration

    /// X-axis display configuration for different time ranges
    /// Used in: WeightChartViewModel for axis mark generation
    enum XAxis {
        /// Day view: Show marks every 3 hours
        /// 24-hour period divided into 8 intervals for readability
        static let dayHourInterval: Int = 3

        /// Day view: Total hours in a day
        static let dayHourMax: Int = 24

        /// Week view: Show marks for each day
        /// 7 days = 7 axis marks
        static let weekDays: Int = 7

        /// Month view: Show marks approximately every week
        /// ~4-5 marks per month for clean axis
        static let monthWeekInterval: Int = 7

        /// Three months view: Show marks approximately every 2 weeks
        /// ~6-7 marks for three months
        static let threeMonthsWeekInterval: Int = 14

        /// Year view: Show marks approximately monthly
        /// ~12 marks for full year
        static let yearMonthInterval: Int = 30
    }

    // MARK: - Chart Y-Axis Step Sizes

    /// Step sizes for Y-axis gridlines based on data range
    /// Used in: WeightChartViewModel for gridline generation
    /// Rationale: Different data ranges need different gridline densities
    enum YAxisStep {
        /// Step size for very small ranges (< 5 lbs): 1 lb per gridline
        static let verySmall: Double = 1.0

        /// Step size for small ranges (5-10 lbs): 2 lbs per gridline
        static let small: Double = 2.0

        /// Step size for medium ranges (10-20 lbs): 5 lbs per gridline
        static let medium: Double = 5.0

        /// Step size for large ranges (20-50 lbs): 10 lbs per gridline
        static let large: Double = 10.0

        /// Step size for very large ranges (> 50 lbs): 20 lbs per gridline
        static let veryLarge: Double = 20.0

        /// Thresholds for determining which step size to use
        enum Threshold {
            static let verySmall: Double = 5.0  // Range < 5 lbs
            static let small: Double = 10.0     // Range < 10 lbs
            static let medium: Double = 20.0    // Range < 20 lbs
            static let large: Double = 50.0     // Range < 50 lbs
            // Range >= 50 lbs uses veryLarge step
        }
    }

    // MARK: - Data Point Display

    /// Constants for displaying data points on charts
    enum DataPoint {
        /// Minimum number of data points required to show chart
        /// Below this threshold, show empty state message
        static let minimumForDisplay: Int = 1

        /// Ideal number of data points for smooth curve interpolation
        /// Used to determine if curve or line interpolation should be used
        static let minimumForSmoothCurve: Int = 3

        /// Maximum number of points to display without aggregation
        /// Above this, consider aggregating data for performance
        static let maximumWithoutAggregation: Int = 365
    }

    // MARK: - Chart Dimensions

    /// Visual styling constants for chart rendering
    enum Dimensions {
        /// Line chart stroke width (2.0 points)
        static let lineWidth: Double = 2.0

        /// Data point marker size (8.0 points diameter)
        static let pointSize: Double = 8.0

        /// Goal line stroke width (2.0 points)
        static let goalLineWidth: Double = 2.0

        /// Goal line dash pattern [4, 4] (4 points on, 4 points off)
        static let goalLineDashLength: Double = 4.0

        /// Chart corner radius (12.0 points)
        static let cornerRadius: Double = 12.0

        /// Chart padding (16.0 points)
        static let padding: Double = 16.0
    }

    // MARK: - Animation

    /// Chart animation constants
    /// Separate from general AnimationConstants as these are chart-specific
    enum Animation {
        /// Duration for chart data updates (0.35 seconds)
        /// Smooth but not too slow for frequent updates
        static let dataUpdate: Double = 0.35

        /// Duration for range changes (0.4 seconds)
        /// Slightly longer for more dramatic transitions
        static let rangeChange: Double = 0.4

        /// Spring response for data point animations
        static let springResponse: Double = 0.6

        /// Spring damping fraction for data point animations
        static let springDamping: Double = 0.8
    }
}

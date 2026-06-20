import { render, screen } from '@testing-library/react';
import WeatherPanel from '../components/WeatherPanel';
import type { Weather } from '../types/weather';

// ── Fixtures ───────────────────────────────────────────────────────────────

const WEATHER: Weather = {
  location: 'Berlin, Germany',
  latitude: 52.52,
  longitude: 13.405,
  temperature_celsius: 18.3,
  precipitation_mm: 0.0,
  condition: 'Clear sky',
};

// ── Helpers ────────────────────────────────────────────────────────────────

function renderPanel(props: Partial<Parameters<typeof WeatherPanel>[0]> = {}) {
  const defaults = { data: null, loading: false, error: null };
  return render(<WeatherPanel {...defaults} {...props} />);
}

// ── Tests ──────────────────────────────────────────────────────────────────

describe('WeatherPanel', () => {
  describe('empty state (null data, not loading, no error)', () => {
    it('renders nothing', () => {
      const { container } = renderPanel();
      expect(container).toBeEmptyDOMElement();
    });
  });

  describe('loading state', () => {
    it('renders a loading status region', () => {
      renderPanel({ loading: true });
      expect(screen.getByRole('status', { name: /loading weather data/i })).toBeInTheDocument();
    });

    it('shows "Fetching" text', () => {
      renderPanel({ loading: true });
      expect(screen.getByText(/fetching/i)).toBeInTheDocument();
    });

    it('does not show weather data while loading', () => {
      renderPanel({ loading: true, data: WEATHER });
      expect(screen.queryByText('Berlin, Germany')).not.toBeInTheDocument();
    });
  });

  describe('error state', () => {
    it('renders an alert region', () => {
      renderPanel({ error: 'Location not found.' });
      expect(screen.getByRole('alert')).toBeInTheDocument();
    });

    it('displays the error message', () => {
      renderPanel({ error: 'Location not found.' });
      expect(screen.getByText('Location not found.')).toBeInTheDocument();
    });

    it('shows a recovery hint', () => {
      renderPanel({ error: 'Oops' });
      expect(
        screen.getByText(/try a different city name or click the map/i),
      ).toBeInTheDocument();
    });

    it('does not show data alongside an error', () => {
      renderPanel({ error: 'bad', data: WEATHER });
      expect(screen.queryByText('Berlin, Germany')).not.toBeInTheDocument();
    });
  });

  describe('data state', () => {
    beforeEach(() => { renderPanel({ data: WEATHER }); });

    it('has an accessible aside landmark', () => {
      expect(screen.getByRole('complementary', { name: /weather results/i })).toBeInTheDocument();
    });

    it('renders the location name', () => {
      expect(screen.getByText('Berlin, Germany')).toBeInTheDocument();
    });

    it('renders temperature with accessible aria-label', () => {
      expect(
        screen.getByLabelText(/18\.3 degrees celsius/i),
      ).toBeInTheDocument();
    });

    it('renders precipitation value', () => {
      expect(screen.getByText('0.0 mm')).toBeInTheDocument();
    });

    it('renders the condition', () => {
      expect(screen.getByText('Clear sky')).toBeInTheDocument();
    });

    it('renders latitude and longitude', () => {
      expect(screen.getByText('52.5200°')).toBeInTheDocument();
      expect(screen.getByText('13.4050°')).toBeInTheDocument();
    });
  });

  describe('transition from loading to data', () => {
    it('shows data once loading clears', () => {
      const { rerender } = render(
        <WeatherPanel data={null} loading={true} error={null} />,
      );
      expect(screen.queryByText('Berlin, Germany')).not.toBeInTheDocument();

      rerender(<WeatherPanel data={WEATHER} loading={false} error={null} />);
      expect(screen.getByText('Berlin, Germany')).toBeInTheDocument();
    });
  });
});

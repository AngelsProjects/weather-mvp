import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import SearchForm from '../components/SearchForm';

// ── Helpers ────────────────────────────────────────────────────────────────

interface Props {
  onSearch?: (location: string) => void;
  onLocate?: () => void;
  loading?: boolean;
  geoLoading?: boolean;
}

function renderForm(props: Props = {}) {
  const onSearch = props.onSearch ?? vi.fn();
  const onLocate = props.onLocate ?? vi.fn();
  const user = userEvent.setup();

  render(
    <SearchForm
      onSearch={onSearch}
      onLocate={onLocate}
      loading={props.loading ?? false}
      geoLoading={props.geoLoading ?? false}
    />,
  );

  return { onSearch, onLocate, user };
}

// ── Tests ──────────────────────────────────────────────────────────────────

describe('SearchForm', () => {
  describe('accessibility', () => {
    it('has a search landmark', () => {
      renderForm();
      expect(screen.getByRole('search', { name: /weather location search/i })).toBeInTheDocument();
    });

    it('has a labelled text input', () => {
      renderForm();
      expect(
        screen.getByRole('searchbox', { name: /search by city or place name/i }),
      ).toBeInTheDocument();
    });

    it('has a search submit button', () => {
      renderForm();
      expect(
        screen.getByRole('button', { name: /search this location/i }),
      ).toBeInTheDocument();
    });

    it('has a geolocation button', () => {
      renderForm();
      expect(
        screen.getByRole('button', { name: /use my current location/i }),
      ).toBeInTheDocument();
    });
  });

  describe('initial render', () => {
    it('search button is disabled when input is empty', () => {
      renderForm();
      expect(screen.getByRole('button', { name: /search this location/i })).toBeDisabled();
    });

    it('geo button is enabled when idle', () => {
      renderForm();
      expect(screen.getByRole('button', { name: /use my current location/i })).toBeEnabled();
    });
  });

  describe('typing and submitting a location', () => {
    it('enables search button once input is non-empty', async () => {
      const { user } = renderForm();
      const input = screen.getByRole('searchbox');

      await user.type(input, 'Paris');

      expect(screen.getByRole('button', { name: /search this location/i })).toBeEnabled();
    });

    it('calls onSearch with the trimmed query on submit', async () => {
      const { user, onSearch } = renderForm();
      const input = screen.getByRole('searchbox');

      await user.type(input, '  Tokyo  ');
      await user.click(screen.getByRole('button', { name: /search this location/i }));

      expect(onSearch).toHaveBeenCalledOnce();
      expect(onSearch).toHaveBeenCalledWith('Tokyo');
    });

    it('calls onSearch when Enter is pressed in the input', async () => {
      const { user, onSearch } = renderForm();
      const input = screen.getByRole('searchbox');

      await user.type(input, 'Madrid');
      await user.keyboard('{Enter}');

      expect(onSearch).toHaveBeenCalledWith('Madrid');
    });

    it('does not call onSearch when input is only whitespace', async () => {
      const { user, onSearch } = renderForm();
      const input = screen.getByRole('searchbox');

      await user.type(input, '   ');
      await user.keyboard('{Enter}');

      expect(onSearch).not.toHaveBeenCalled();
    });
  });

  describe('geolocation button', () => {
    it('calls onLocate when clicked', async () => {
      const { user, onLocate } = renderForm();

      await user.click(screen.getByRole('button', { name: /use my current location/i }));

      expect(onLocate).toHaveBeenCalledOnce();
    });
  });

  describe('loading state', () => {
    it('disables the input while loading', () => {
      renderForm({ loading: true });
      expect(screen.getByRole('searchbox')).toBeDisabled();
    });

    it('disables the search button while loading', () => {
      renderForm({ loading: true });
      expect(screen.getByRole('button', { name: /searching/i })).toBeDisabled();
    });

    it('disables the geo button while loading', () => {
      renderForm({ loading: true });
      expect(screen.getByRole('button', { name: /use my current location/i })).toBeDisabled();
    });

    it('shows aria-busy on search button while loading', () => {
      renderForm({ loading: true });
      // aria-busy="true" on search button
      const searchBtn = screen.getByRole('button', { name: /searching/i });
      expect(searchBtn).toHaveAttribute('aria-busy', 'true');
    });
  });

  describe('geoLoading state', () => {
    it('disables input while geolocating', () => {
      renderForm({ geoLoading: true });
      expect(screen.getByRole('searchbox')).toBeDisabled();
    });

    it('shows aria-busy on geo button while locating', () => {
      renderForm({ geoLoading: true });
      const geoBtn = screen.getByRole('button', { name: /detecting your location/i });
      expect(geoBtn).toHaveAttribute('aria-busy', 'true');
    });

    it('disables geo button while geolocating', () => {
      renderForm({ geoLoading: true });
      expect(
        screen.getByRole('button', { name: /detecting your location/i }),
      ).toBeDisabled();
    });
  });
});

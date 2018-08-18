import { IStats } from './get-stats';
import { result, resultJSON } from './log';

export const writeReport = async (stats: IStats, doJSON: boolean) => {
  const { total } = stats;
  const results = stats.files.concat(total);
  let writer = result; // not sure if this is the right way to do it...
  if (doJSON) {
    writer = resultJSON;
  }
  results.forEach(({ path, pretty, raw }) => {
    writer(path, pretty.before, pretty.after, pretty.saving, raw.percentSaving, 100);
  });
};
